import { test } from 'node:test';
import assert from 'node:assert/strict';
import { prisma } from '../src/lib/prisma.js';
import { startThread, createMessage } from '../src/modules/chat/repositories/chat.repository.js';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  attachmentExtension,
  mediaLink,
  readMedia,
  sendMedia,
} from '../src/modules/chat/controllers/chat-media.controller.js';

test('profile and listing entry points reuse the same thread in either direction', async (t) => {
  const chats = new Map<string, { id: string; threadId?: string; listingId?: string }>();
  const tx = {
    $executeRaw: async () => 0,
    $queryRaw: async () => [],
    conversationMember: { findFirst: async () => null },
    conversation: {
      upsert: async ({ where, create }: any) => {
        if (!chats.has(where.pairKey)) chats.set(where.pairKey, { ...create, id: String(chats.size + 1) });
        return chats.get(where.pairKey);
      },
    },
  };
  t.mock.method(prisma, '$transaction', async (run: any) => run(tx));
  const root = await startThread('buyer', 'shop', 'phone');
  assert.equal((await startThread('buyer', 'shop', 'tv')).id, root.id);
  assert.equal((await startThread('shop', 'buyer')).id, root.id);
  assert.equal((await startThread('buyer', 'shop', 'phone')).id, root.id);
  assert.notEqual((await startThread('another', 'shop')).id, root.id);
  assert.deepEqual(
    [...chats.values()].filter((c) => c.threadId === root.id).map((c) => c.listingId),
    ['phone', 'tv'],
  );
});

test('a block on the shared thread denies text, product inquiries and media in both directions', async (t) => {
  const root = 'shared';
  const tx = {
    $queryRaw: async () => [],
    conversationMember: {
      findFirst: async ({ where }: any) => {
        assert.deepEqual(where, { conversationId: root, blocked: true });
        return { userId: 'buyer' };
      },
    },
  };
  t.mock.method(prisma, '$transaction', async (run: any) => run(tx));
  for (const user of ['shop', 'buyer']) {
    for (const [context, media] of [
      [undefined, undefined],
      ['phone-context', undefined],
      [undefined, 'clip.mp4'],
    ]) {
      await assert.rejects(createMessage(root, user, 'client', 'message', context, media), {
        statusCode: 403,
      });
    }
  }
});

test('private photo and video uploads survive retries and support playback ranges', async (t) => {
  const dir = await mkdtemp(join(tmpdir(), 'restore-chat-media-'));
  process.env.STORAGE_DRIVER = 'disk';
  process.env.STORAGE_DISK_ROOT = dir;
  process.env.JWT_SECRET = 'isolated-chat-media-test-only';
  t.after(() => rm(dir, { recursive: true, force: true }));
  const messages = new Map<string, any>();
  Object.assign(prisma.conversation, {
    findFirst: async ({ where }: any) => (where.members.some.userId === 'buyer' ? { threadId: null } : null),
  });
  Object.assign(prisma.conversationMember, {
    findMany: async () => [{ userId: 'buyer' }, { userId: 'shop' }],
  });
  Object.assign(prisma.message, {
    findUnique: async ({ where }: any) => messages.get(where.senderId_clientId.clientId) ?? null,
    findFirst: async ({ where }: any) =>
      [...messages.values()].find((m) => m.id === where.id && m.conversationId === 'shared') ?? null,
  });
  const tx = {
    $queryRaw: async () => [],
    conversationMember: { findFirst: async () => null, updateMany: async () => ({}) },
    conversation: { updateMany: async () => ({}) },
    user: { update: async () => ({}) },
    message: {
      create: async ({ data }: any) => {
        const result = { ...data, id: 'msg-' + data.clientId };
        messages.set(data.clientId, result);
        return result;
      },
    },
  };
  t.mock.method(prisma, '$transaction', async (run: any) => run(tx));
  const invoke = async (handler: any, req: any) => {
    const result: any = { status: 200 };
    const res = {
      status(code: number) {
        result.status = code;
        return res;
      },
      json(body: any) {
        result.body = body;
      },
      send(body: any) {
        result.body = body;
      },
      type() {
        return res;
      },
      setHeader() {
        return res;
      },
      set() {
        return res;
      },
    };
    await handler(req, res, (error: any) => {
      throw error;
    });
    return result;
  };
  for (const [clientId, bytes] of [
    ['photo', Buffer.from([255, 216, 255, 1])],
    ['video', Buffer.from('0000ftypisom0000')],
  ] as const) {
    const req = { params: { id: 'shared' }, user: { userId: 'buyer' }, query: { clientId }, body: bytes };
    const first = await invoke(sendMedia, req);
    assert.equal(first.status, 201);
    assert.equal((await invoke(sendMedia, req)).status, 200);
    const read = { ...req, params: { id: 'shared', messageId: first.body.data.id } };
    await assert.rejects(invoke(mediaLink, { ...read, user: { userId: 'stranger' } }), { statusCode: 404 });
    const link = await invoke(mediaLink, read);
    const ticket = new URL(link.body.data.url, 'http://local.test').searchParams.get('ticket');
    assert.deepEqual((await invoke(readMedia, { query: { ticket }, range: () => undefined })).body, bytes);
    const range = Object.assign([{ start: 1, end: 2 }], { type: 'bytes' });
    const chunk = await invoke(readMedia, { query: { ticket }, range: () => range });
    assert.equal(chunk.status, 206);
    assert.deepEqual(chunk.body, bytes.subarray(1, 3));
  }
  assert.equal(messages.size, 2);
});

test('attachments are classified by content and unsupported formats are rejected', () => {
  assert.equal(attachmentExtension(Buffer.from([255, 216, 255, 1])), 'jpg');
  assert.equal(attachmentExtension(Buffer.from('0000ftypisom0000')), 'mp4');
  assert.equal(attachmentExtension(Buffer.from('0000ftypqt  0000')), 'mov');
  assert.throws(() => attachmentExtension(Buffer.from('0000ftypheic0000')), { statusCode: 415 });
  assert.throws(() => attachmentExtension(Buffer.alloc(0)), { statusCode: 415 });
});
