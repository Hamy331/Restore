import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {
  contentTypeOf, deliveryUrl, getObject, putObject, readStored, removeObject, storageDriver, thumbWidth,
  validateStorageEnvironment,
} from './storage.service.js';

const ENV_KEYS = ['STORAGE_DRIVER', 'STORAGE_DISK_ROOT', 'CLOUDINARY_URL', 'CLOUDINARY_ROOT_FOLDER'];

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
  await withEnv({ STORAGE_DRIVER: 'supabase' }, async () => assert.throws(storageDriver, /STORAGE_DRIVER/));
});

test('contentTypeOf maps image and video extensions', () => {
  assert.equal(contentTypeOf('a.jpg'), 'image/jpeg');
  assert.equal(contentTypeOf('a.png'), 'image/png');
  assert.equal(contentTypeOf('a.webp'), 'image/webp');
  assert.equal(contentTypeOf('a.mp4'), 'video/mp4');
});

test('thumbWidth picks the smallest allowed size that is wide enough', () => {
  assert.equal(thumbWidth('100'), 240);
  assert.equal(thumbWidth('240'), 240);
  assert.equal(thumbWidth('481'), 960);
  assert.equal(thumbWidth(['300', '900']), 480);
  for (const value of [undefined, '', '0', '-1', 'abc', '961', '1.5']) assert.equal(thumbWidth(value), null, String(value));
});

test('disk driver: put, get, remove; no CDN URL; missing file reads as null', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'storage-'));
  try {
    await withEnv({ STORAGE_DISK_ROOT: root }, async () => {
      await putObject('listings', 'a.png', Buffer.from('png'));
      assert.equal((await getObject('listings', 'a.png'))?.toString(), 'png');
      assert.equal(deliveryUrl('listings', 'a.png', 240), null);
      assert.deepEqual(await readStored('listings', 'a.png'), { bytes: Buffer.from('png'), contentType: 'image/png' });
      await assert.rejects(putObject('listings', 'a.png', Buffer.from('again')), { code: 'EEXIST' });
      await removeObject('listings', 'a.png');
      await removeObject('listings', 'a.png');
      assert.equal(await getObject('listings', 'a.png'), null);
      assert.equal(await readStored('listings', 'a.png'), null);
      await assert.rejects(async () => getObject('listings', '../secret'), /Invalid storage object name/);
    });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('cloudinary driver: public areas get plain CDN URLs, gated areas get signed URLs', async () => {
  await withEnv({ STORAGE_DRIVER: 'cloudinary', CLOUDINARY_URL: 'cloudinary://123:secret@demo' }, async () => {
    validateStorageEnvironment();
    const avatar = deliveryUrl('avatars', 'u_1.jpg')!;
    assert.match(avatar, /^https:\/\/res\.cloudinary\.com\/demo\/image\/upload\/(v1\/)?media\/avatars\/u_1\.jpg$/);
    const thumb = deliveryUrl('feeds', 'u_2.png', 480)!;
    assert.match(thumb, /\/image\/upload\/c_limit,f_auto,q_auto,w_480\/(v1\/)?media\/feeds\/u_2\.png$/);
    const listing = deliveryUrl('listings', 'x.webp', 240)!;
    assert.match(listing, /\/image\/authenticated\/s--[A-Za-z0-9_-]{8}--\/c_limit,f_auto,q_auto,w_240\/(v1\/)?media\/listings\/x\.webp$/);
    const video = deliveryUrl('chat', 'v.mp4')!;
    assert.match(video, /\/video\/authenticated\/s--[A-Za-z0-9_-]{8}--\/(v1\/)?media\/chat\/v\.mp4$/);
  });
});
