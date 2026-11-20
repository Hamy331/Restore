import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import sharp from 'sharp';
import { readThumbnail, removeThumbnails, setResizerForTesting, thumbName, thumbWidth } from './image-thumbnail.service.js';
import { putObject } from './storage.service.js';

/** Chạy [fn] với storage ổ đĩa trong thư mục tạm */
async function withDiskStorage(fn: (root: string) => Promise<void>) {
  const root = await mkdtemp(path.join(tmpdir(), 'thumb-'));
  const saved = { driver: process.env.STORAGE_DRIVER, root: process.env.STORAGE_DISK_ROOT };
  process.env.STORAGE_DRIVER = 'disk';
  process.env.STORAGE_DISK_ROOT = root;
  try {
    await fn(root);
  } finally {
    for (const [key, value] of [['STORAGE_DRIVER', saved.driver], ['STORAGE_DISK_ROOT', saved.root]] as const) {
      if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
    await rm(root, { recursive: true, force: true });
  }
}

/** Ảnh JPEG nhiễu 2000x1500 (nặng như ảnh chụp thật, nén kém) */
const photo = () => sharp(Buffer.from(Array.from({ length: 2000 * 1500 * 3 }, (_, i) => (i * 7919) % 251)),
  { raw: { width: 2000, height: 1500, channels: 3 } }).jpeg({ quality: 90 }).toBuffer();

test('thumbWidth picks the smallest allowed size that is wide enough', () => {
  assert.equal(thumbWidth('100'), 240);
  assert.equal(thumbWidth('240'), 240);
  assert.equal(thumbWidth('480'), 480);
  assert.equal(thumbWidth('481'), 960);
  assert.equal(thumbWidth(['300', '900']), 480);
  for (const value of [undefined, '', '0', '-5', '1.5', 'abc', '961', '4000', '999999']) {
    assert.equal(thumbWidth(value), null, String(value));
  }
  assert.equal(thumbName('abc.jpg', 480), 'abc.w480.webp');
});

// Chạy trước mọi setResizerForTesting để dùng sharp thật (nạp động trong service)
test('thumbnails are resized WebP, stored once and reused', async () => {
  await withDiskStorage(async (root) => {
    const original = await photo();
    await putObject('listings', 'a.jpg', original);
    let reads = 0;
    const load = async () => { reads++; return original; };

    const first = await readThumbnail('listings', 'a.jpg', 480, load);
    assert.ok(first);
    const meta = await sharp(first).metadata();
    assert.equal(meta.format, 'webp');
    assert.equal(meta.width, 480);
    assert.equal(meta.height, 360);
    assert.ok(first.length < original.length / 5, `${first.length} vs ${original.length}`);
    assert.deepEqual((await readdir(path.join(root, 'listings'))).sort(), ['a.jpg', 'a.w480.webp']);

    // Lần sau lấy từ bộ nhớ, không đọc lại ảnh gốc
    assert.deepEqual(await readThumbnail('listings', 'a.jpg', 480, load), first);
    assert.equal(reads, 1);

    // Server khởi động lại (mất bộ nhớ): đọc thumbnail đã lưu, không tạo lại
    setResizerForTesting(async () => { throw new Error('should not resize again'); });
    assert.deepEqual(await readThumbnail('listings', 'a.jpg', 480, load), first);
    assert.equal(reads, 1);

    await removeThumbnails('listings', 'a.jpg');
    assert.deepEqual(await readdir(path.join(root, 'listings')), ['a.jpg']);
  });
});

test('falls back to the original when sharp is missing, the image is broken or already small', async () => {
  await withDiskStorage(async () => {
    setResizerForTesting(null);
    assert.equal(await readThumbnail('feeds', 'b.jpg', 240, async () => Buffer.from('x')), null);

    setResizerForTesting(async () => { throw new Error('Input buffer contains unsupported image format'); });
    assert.equal(await readThumbnail('feeds', 'c.jpg', 240, async () => Buffer.from('not an image')), null);

    setResizerForTesting(async (bytes) => Buffer.concat([bytes, bytes]));
    assert.equal(await readThumbnail('feeds', 'd.webp', 240, async () => Buffer.from('tiny')), null);

    // Ảnh gốc không còn
    setResizerForTesting(async (bytes) => bytes.subarray(0, 1));
    assert.equal(await readThumbnail('feeds', 'e.jpg', 240, async () => null), null);
  });
});

test('concurrent requests for the same thumbnail resize only once', async () => {
  await withDiskStorage(async () => {
    let resizes = 0;
    setResizerForTesting(async (bytes) => { resizes++; await new Promise((r) => setTimeout(r, 20)); return bytes.subarray(0, 10); });
    const load = async () => Buffer.alloc(1000, 1);
    const results = await Promise.all(Array.from({ length: 5 }, () => readThumbnail('posters', 'f.png', 960, load)));
    assert.equal(resizes, 1);
    for (const bytes of results) assert.equal(bytes?.length, 10);
  });
});
