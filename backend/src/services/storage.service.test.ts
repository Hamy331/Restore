import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { contentTypeOf, getObject, listDiskObjects, putObject, removeObject, storageDriver, validateStorageEnvironment } from './storage.service.js';

const ENV_KEYS = ['STORAGE_DRIVER', 'STORAGE_DISK_ROOT', 'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_STORAGE_BUCKET'];

/** Chạy [work] với biến môi trường tạm, trả lại như cũ sau đó */
async function withEnv(env: Record<string, string>, work: () => Promise<void>) {
  const saved = Object.fromEntries(ENV_KEYS.map((key) => [key, process.env[key]]));
  for (const key of ENV_KEYS) delete process.env[key];
  Object.assign(process.env, env);
  try {
    await work();
  } finally {
    for (const key of ENV_KEYS) {
      if (saved[key] === undefined) delete process.env[key];
      else process.env[key] = saved[key];
    }
  }
}

test('driver defaults to disk and rejects unknown values', async () => {
  await withEnv({}, async () => assert.equal(storageDriver(), 'disk'));
  await withEnv({ STORAGE_DRIVER: 's3' }, async () => assert.throws(storageDriver, /STORAGE_DRIVER/));
  await withEnv({ STORAGE_DRIVER: 'supabase' }, async () => assert.throws(validateStorageEnvironment, /SUPABASE_URL/));
});

test('contentTypeOf maps image extensions', () => {
  assert.equal(contentTypeOf('a.jpg'), 'image/jpeg');
  assert.equal(contentTypeOf('a.png'), 'image/png');
  assert.equal(contentTypeOf('a.webp'), 'image/webp');
});

test('disk driver: put, get, remove; missing file reads as null', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'storage-'));
  try {
    await withEnv({ STORAGE_DISK_ROOT: root }, async () => {
      assert.deepEqual(await listDiskObjects('listings'), []);
      await putObject('listings', 'a.png', Buffer.from('png'));
      assert.deepEqual(await listDiskObjects('listings'), ['a.png']);
      assert.equal((await getObject('listings', 'a.png'))?.toString(), 'png');
      await assert.rejects(putObject('listings', 'a.png', Buffer.from('again')), { code: 'EEXIST' });
      await removeObject('listings', 'a.png');
      await removeObject('listings', 'a.png');
      assert.equal(await getObject('listings', 'a.png'), null);
      await assert.rejects(async () => getObject('listings', '../secret'), /Invalid storage object name/);
    });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('supabase driver calls the Storage REST API with the service key', async () => {
  const calls: { method: string; url: string; headers: Record<string, string>; body?: unknown }[] = [];
  const realFetch = globalThis.fetch;
  globalThis.fetch = (async (input: string | URL | Request, init?: RequestInit) => {
    const call = { method: init?.method ?? 'GET', url: String(input), headers: init?.headers as Record<string, string>, body: init?.body };
    calls.push(call);
    if (call.method === 'GET' && call.url.endsWith('/missing.jpg')) {
      return new Response('{"statusCode":"404","error":"not_found","message":"Object not found"}', { status: 400 });
    }
    if (call.method === 'GET') return new Response(new Uint8Array([1, 2, 3]));
    if (call.method === 'POST' && call.url.endsWith('/fail.jpg')) return new Response('boom', { status: 500 });
    if (call.method === 'POST' && call.url.endsWith('/dup.jpg')) {
      return new Response('{"statusCode":"409","error":"Duplicate","message":"The resource already exists"}', { status: 400 });
    }
    return new Response('{}');
  }) as typeof fetch;
  try {
    await withEnv({ STORAGE_DRIVER: 'supabase', SUPABASE_URL: 'https://p.supabase.co/', SUPABASE_SERVICE_ROLE_KEY: 'key' }, async () => {
      await putObject('admin', 'x.webp', Buffer.from('w'));
      assert.deepEqual(await getObject('admin', 'x.webp'), Buffer.from([1, 2, 3]));
      assert.equal(await getObject('admin', 'missing.jpg'), null);
      await removeObject('admin', 'x.webp');
      await assert.rejects(putObject('admin', 'fail.jpg', Buffer.from('f')), /500 boom/);
      await assert.rejects(putObject('admin', 'dup.jpg', Buffer.from('d')), { code: 'EEXIST' });
    });
  } finally {
    globalThis.fetch = realFetch;
  }
  const [put, get, , remove] = calls;
  assert.equal(put!.method, 'POST');
  assert.equal(put!.url, 'https://p.supabase.co/storage/v1/object/media/admin/x.webp');
  assert.equal(put!.headers.Authorization, 'Bearer key');
  assert.equal(put!.headers['Content-Type'], 'image/webp');
  assert.equal(put!.headers['x-upsert'], 'false');
  assert.equal(get!.url, 'https://p.supabase.co/storage/v1/object/media/admin/x.webp');
  assert.equal(remove!.method, 'DELETE');
  assert.equal(remove!.url, 'https://p.supabase.co/storage/v1/object/media');
  assert.deepEqual(JSON.parse(String(remove!.body)), { prefixes: ['admin/x.webp'] });
});
