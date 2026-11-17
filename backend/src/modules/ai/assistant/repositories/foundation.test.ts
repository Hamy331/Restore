import assert from 'node:assert/strict';
import { test } from 'node:test';
import { prisma } from '../../../../lib/prisma.js';
import { begin, finish, history } from './assistant.repository.js';

test('ownership, replay and busy leases are checked before quota consumption', async t => {
  let conversation: any = { userId: 'other' }, previous: any = null;
  const writes: string[] = [];
  const tx = {
    aiConversation: { upsert: async () => conversation, update: async () => writes.push('lease') },
    aiTurn: { findUnique: async () => previous, count: async () => 0 },
    aiUsage: { findUnique: async () => null, upsert: async () => writes.push('usage') },
  };
  t.mock.method(prisma, '$transaction', async (work: any) => work(tx));
  await assert.rejects(begin('self', 'chat', 'r', 'hello'), { code: 'AI_CONVERSATION_NOT_FOUND' });
  conversation = { userId: 'self', busyUntil: new Date(Date.now() + 10000) };
  previous = { input: 'hello', response: { text: 'cached', listings: [], sources: [] } };
  assert.equal((await begin('self', 'chat', 'r', 'hello')).cached?.text, 'cached');
  await assert.rejects(begin('self', 'chat', 'r', 'changed'), { code: 'AI_REQUEST_CHANGED' });
  previous = null;
  await assert.rejects(begin('self', 'chat', 'r', 'hello'), { code: 'AI_BUSY' });
  assert.deepEqual(writes, []);
  conversation.busyUntil = null;
  assert.ok((await begin('self', 'chat', 'r', 'hello')).lease);
  assert.deepEqual(writes, ['usage', 'lease']);
});

test('rolling/day quotas and burst limits reject requests before lease writes', async t => {
  let rapid = 0, usage: any = null, writes = 0;
  const tx = {
    aiConversation: { upsert: async () => ({ userId: 'self' }), update: async () => { writes++; } },
    aiTurn: { findUnique: async () => null, count: async () => rapid },
    aiUsage: { findUnique: async () => usage, upsert: async () => { writes++; } },
  };
  t.mock.method(prisma, '$transaction', async (work: any) => work(tx));
  const now = new Date(), today = new Date(now.toISOString().slice(0, 10));
  for (const [windowCount, dayCount] of [[20, 20], [1, 100]]) {
    usage = { windowStart: now, windowCount, dayStart: today, dayCount };
    await assert.rejects(begin('self', 'chat', 'r', 'hello'), { code: 'AI_RATE_LIMIT' });
  }
  usage = null; rapid = 5;
  await assert.rejects(begin('self', 'chat', 'r', 'hello'), { code: 'AI_RATE_LIMIT' });
  assert.equal(writes, 0);
});

test('finish checks its lease and atomically stores sanitized history', async t => {
  let valid = false;
  const turns: any[] = [];
  t.mock.method(prisma, '$transaction', async (work: any) => work({
    aiConversation: { updateMany: async () => ({ count: valid ? 1 : 0 }) },
    aiTurn: { create: async ({ data }: any) => turns.push(data) },
  }));
  const response = { text: 'token: private-token-123', listings: [], sources: [] };
  await assert.rejects(finish('chat', 'lease', 'r', 'hi', response, []), { code: 'AI_LEASE_EXPIRED' });
  assert.equal(turns.length, 0);
  valid = true;
  await finish('chat', 'lease', 'r', 'token: private-token-123', response, []);
  assert.doesNotMatch(JSON.stringify(turns), /private-token-123/);
});

test('history requires ownership before reading turns', async t => {
  const findFirst = prisma.aiConversation.findFirst;
  prisma.aiConversation.findFirst = (async () => null) as typeof findFirst;
  t.after(() => { prisma.aiConversation.findFirst = findFirst; });
  await assert.rejects(history('self', 'foreign'), { code: 'AI_CONVERSATION_NOT_FOUND' });
});
