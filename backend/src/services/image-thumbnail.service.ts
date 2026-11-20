import path from 'node:path';
import { getObject, putObject, removeObject, type StorageArea } from './storage.service.js';

/**
 * Ảnh thu nhỏ (thumbnail) cho danh sách: app gửi `?w=` theo bề ngang cần hiển thị,
 * server trả bản WebP nhỏ thay vì ảnh gốc vài MB.
 *
 *  - Chỉ có vài cỡ cố định [THUMB_WIDTHS] (không cho tạo cỡ tùy ý làm đầy storage).
 *  - Tạo lần đầu có người xem rồi lưu cạnh ảnh gốc: "<tên>.w480.webp" (tên này không khớp
 *    regex tên ảnh gốc nên không ai gọi thẳng được).
 *  - Giữ thêm trong bộ nhớ (LRU theo dung lượng) để lần sau khỏi tải từ storage.
 *  - Chưa cài `sharp` hoặc ảnh lỗi thì trả ảnh gốc, app vẫn chạy như cũ.
 */
export const THUMB_WIDTHS = [240, 480, 960] as const;
export type ThumbWidth = (typeof THUMB_WIDTHS)[number];

const MEMORY_LIMIT = 64 * 1024 * 1024;
const QUALITY = 78;

/** Cỡ thumbnail nhỏ nhất đủ cho bề ngang [value] (query `w`); không hợp lệ hoặc lớn hơn mọi cỡ thì null (ảnh gốc) */
export function thumbWidth(value: unknown): ThumbWidth | null {
  const raw = Array.isArray(value) ? value[0] : value;
  if (typeof raw !== 'string' || !/^[1-9]\d{0,4}$/.test(raw)) return null;
  const width = Number(raw);
  return THUMB_WIDTHS.find((size) => size >= width) ?? null;
}

/** Tên file thumbnail của ảnh [name] */
export const thumbName = (name: string, width: ThumbWidth) => `${path.parse(name).name}.w${width}.webp`;

/* ---------- sharp: nạp khi cần, thiếu thì bỏ qua ---------- */

type Resize = (bytes: Buffer, width: number) => Promise<Buffer>;
let resizer: Promise<Resize | null> | undefined;

/** Thay hàm thu nhỏ ảnh trong test */
export function setResizerForTesting(fn: Resize | null) {
  resizer = Promise.resolve(fn);
  memory.clear();
  memoryBytes = 0;
}

function loadResizer(): Promise<Resize | null> {
  return (resizer ??= import('sharp')
    .then(({ default: sharp }) => (bytes: Buffer, width: number) =>
      sharp(bytes, { failOn: 'none' })
        .rotate() // theo EXIF, ảnh chụp dọc không bị xoay ngang
        .resize({ width, withoutEnlargement: true })
        .webp({ quality: QUALITY })
        .toBuffer())
    .catch((error: unknown) => {
      console.warn('[thumbnail] sharp not available, serving original images:', (error as Error).message);
      return null;
    }));
}

/* ---------- LRU trong bộ nhớ ---------- */

const memory = new Map<string, Buffer>();
let memoryBytes = 0;

function remember(key: string, bytes: Buffer) {
  if (bytes.length > MEMORY_LIMIT / 8) return;
  const old = memory.get(key);
  if (old) { memory.delete(key); memoryBytes -= old.length; }
  memory.set(key, bytes);
  memoryBytes += bytes.length;
  for (const [oldest, value] of memory) {
    if (memoryBytes <= MEMORY_LIMIT) break;
    memory.delete(oldest);
    memoryBytes -= value.length;
  }
}

function recall(key: string) {
  const bytes = memory.get(key);
  if (bytes) { memory.delete(key); memory.set(key, bytes); }
  return bytes;
}

/* ---------- đọc / tạo thumbnail ---------- */

const inFlight = new Map<string, Promise<Buffer | null>>();

/**
 * Bytes WebP thumbnail của ảnh [name] trong [area]. Null nếu không tạo được (thiếu sharp, ảnh lỗi,
 * ảnh gốc không còn) — khi đó gọi trả ảnh gốc.
 * [original] đọc ảnh gốc (đã kiểm tra quyền xem ở nơi gọi).
 */
export async function readThumbnail(
  area: StorageArea, name: string, width: ThumbWidth, original: () => Promise<Buffer | null>,
): Promise<Buffer | null> {
  const thumb = thumbName(name, width);
  const key = `${area}/${thumb}`;
  const cached = recall(key);
  if (cached) return cached;

  let pending = inFlight.get(key);
  if (!pending) {
    pending = createThumbnail(area, thumb, width, original).finally(() => inFlight.delete(key));
    inFlight.set(key, pending);
  }
  const bytes = await pending;
  if (bytes) remember(key, bytes);
  return bytes;
}

async function createThumbnail(
  area: StorageArea, thumb: string, width: ThumbWidth, original: () => Promise<Buffer | null>,
): Promise<Buffer | null> {
  const stored = await getObject(area, thumb).catch(() => null);
  if (stored) return stored;

  const resize = await loadResizer();
  if (!resize) return null;
  const source = await original();
  if (!source) return null;
  let bytes: Buffer;
  try {
    bytes = await resize(source, width);
  } catch (error) {
    console.warn(`[thumbnail] cannot resize ${area}/${thumb}:`, (error as Error).message);
    return null;
  }
  // Ảnh gốc đã nhỏ hơn thumbnail (VD ảnh WebP nhẹ): dùng luôn ảnh gốc
  if (bytes.length >= source.length) return null;
  await putObject(area, thumb, bytes).catch((error: NodeJS.ErrnoException) => {
    if (error.code !== 'EEXIST') console.warn(`[thumbnail] cannot store ${area}/${thumb}:`, error.message);
  });
  return bytes;
}

/** Xóa mọi thumbnail của ảnh [name] (khi xóa ảnh gốc) */
export async function removeThumbnails(area: StorageArea, name: string) {
  for (const width of THUMB_WIDTHS) {
    const thumb = thumbName(name, width);
    const old = memory.get(`${area}/${thumb}`);
    if (old) { memory.delete(`${area}/${thumb}`); memoryBytes -= old.length; }
    await removeObject(area, thumb).catch(() => {});
  }
}
