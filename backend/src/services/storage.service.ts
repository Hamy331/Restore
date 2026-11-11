import { mkdir, readdir, readFile, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';

/**
 * Lưu file (ảnh tin, ảnh nội dung). Hai driver, chọn bằng STORAGE_DRIVER:
 *  - disk (mặc định): <STORAGE_DISK_ROOT | ./uploads>/<area>/<name>
 *  - supabase: bucket SUPABASE_STORAGE_BUCKET (mặc định "media"), object <area>/<name>.
 *    Bucket để private; server dùng service role key và tự trả ảnh qua API
 *    (/listings/media/:filename, /content/media/:filename) sau khi kiểm tra quyền xem.
 *
 * Module nghiệp vụ chỉ gọi putObject / getObject / removeObject, không biết file nằm ở đâu.
 */

/** Thư mục logic: listings = ảnh tin, admin = ảnh nội dung (bìa bài viết),
 *  feeds = ảnh bài viết bảng tin, avatars = ảnh đại diện, posters = poster shop */
export type StorageArea = 'listings' | 'admin' | 'feeds' | 'avatars' | 'posters';

export const STORAGE_DRIVERS = ['disk', 'supabase'] as const;
export type StorageDriver = (typeof STORAGE_DRIVERS)[number];

const CONTENT_TYPES: Record<string, string> = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' };

/** Content-Type theo đuôi file */
export const contentTypeOf = (name: string) => CONTENT_TYPES[path.extname(name).toLowerCase()] ?? 'application/octet-stream';

/** Driver đang dùng; giá trị lạ thì báo lỗi (validateEnvironment gọi lúc khởi động) */
export function storageDriver(): StorageDriver {
  const value = (process.env.STORAGE_DRIVER?.trim() || 'disk') as StorageDriver;
  if (!STORAGE_DRIVERS.includes(value)) throw new Error(`STORAGE_DRIVER must be one of: ${STORAGE_DRIVERS.join(', ')}.`);
  return value;
}

/** Tên file chỉ gồm chữ, số, '.', '-', '_' (không cho thoát khỏi thư mục) */
function assertName(name: string) {
  if (!/^[A-Za-z0-9._-]+$/.test(name) || name.startsWith('.')) throw new Error(`Invalid storage object name: ${name}`);
}

/* ---------- disk ---------- */

const diskPath = (area: StorageArea, name: string) =>
  path.join(process.env.STORAGE_DISK_ROOT?.trim() || path.join(process.cwd(), 'uploads'), area, name);

const disk = {
  async put(area: StorageArea, name: string, bytes: Buffer) {
    const file = diskPath(area, name);
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, bytes, { flag: 'wx' });
  },
  async get(area: StorageArea, name: string) {
    try {
      return await readFile(diskPath(area, name));
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') return null;
      throw error;
    }
  },
  async remove(area: StorageArea, name: string) {
    await unlink(diskPath(area, name)).catch((error: NodeJS.ErrnoException) => {
      if (error.code !== 'ENOENT') throw error;
    });
  },
};

/* ---------- Supabase Storage (REST API, không cần SDK) ---------- */

function supabaseConfig() {
  const url = process.env.SUPABASE_URL?.trim().replace(/\/+$/, '');
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !key) throw new Error('STORAGE_DRIVER=supabase needs SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
  return { url, key, bucket: process.env.SUPABASE_STORAGE_BUCKET?.trim() || 'media' };
}

/**
 * Header xác thực Supabase. Secret key kiểu mới (`sb_secret_...`) không phải JWT nên chỉ gửi qua `apikey`;
 * service_role key kiểu cũ (JWT, bị Supabase bỏ đầu năm 2027) gửi cả `Authorization`.
 */
export const authHeaders = (key: string): Record<string, string> =>
  key.startsWith('sb_') ? { apikey: key } : { Authorization: `Bearer ${key}`, apikey: key };

async function supabaseRequest(method: string, objectPath: string, init: { body?: BodyInit; headers?: Record<string, string> } = {}) {
  const { url, key, bucket } = supabaseConfig();
  return fetch(`${url}/storage/v1/object/${bucket}${objectPath}`, {
    method,
    body: init.body,
    headers: { ...authHeaders(key), ...init.headers },
  });
}

/** Supabase trả 404, hoặc 400 kèm statusCode "404" / not_found, khi object không có */
async function isNotFound(response: Response) {
  if (response.status === 404) return true;
  if (response.status !== 400) return false;
  const body = await response.clone().text();
  return /not[_ ]found|"404"/i.test(body);
}

/** Supabase trả 409, hoặc 400 kèm statusCode "409" / Duplicate, khi object đã có */
async function isDuplicate(response: Response) {
  if (response.status === 409) return true;
  if (response.status !== 400) return false;
  return /duplicate|"409"/i.test(await response.clone().text());
}

/** Lỗi "đã có file" cùng mã EEXIST với driver disk */
const alreadyExists = (key: string) => Object.assign(new Error(`Storage object already exists: ${key}`), { code: 'EEXIST' });

async function failure(action: string, key: string, response: Response) {
  return new Error(`Supabase Storage ${action} ${key} failed: ${response.status} ${await response.text()}`);
}

const supabase = {
  async put(area: StorageArea, name: string, bytes: Buffer) {
    const key = `${area}/${name}`;
    const response = await supabaseRequest('POST', `/${key}`, {
      body: new Uint8Array(bytes),
      headers: { 'Content-Type': contentTypeOf(name), 'x-upsert': 'false', 'Cache-Control': 'no-store' },
    });
    if (response.ok) return;
    if (await isDuplicate(response)) throw alreadyExists(key);
    throw await failure('upload', key, response);
  },
  async get(area: StorageArea, name: string) {
    const key = `${area}/${name}`;
    const response = await supabaseRequest('GET', `/${key}`);
    if (response.ok) return Buffer.from(await response.arrayBuffer());
    if (await isNotFound(response)) return null;
    throw await failure('download', key, response);
  },
  async remove(area: StorageArea, name: string) {
    const key = `${area}/${name}`;
    const response = await supabaseRequest('DELETE', '', {
      body: JSON.stringify({ prefixes: [key] }),
      headers: { 'Content-Type': 'application/json' },
    });
    if (!response.ok && !await isNotFound(response)) throw await failure('delete', key, response);
  },
};

type Driver = {
  put(area: StorageArea, name: string, bytes: Buffer): Promise<void>;
  get(area: StorageArea, name: string): Promise<Buffer | null>;
  remove(area: StorageArea, name: string): Promise<void>;
};

/** Hai driver, gọi thẳng (không theo STORAGE_DRIVER) khi cần chép giữa chúng, VD scripts/migrate-images.ts */
export const drivers: Record<StorageDriver, Driver> = { disk, supabase };

/* ---------- API dùng chung ---------- */

/** Lưu file mới; trùng tên thì lỗi code EEXIST (tên luôn là UUID nên thực tế không xảy ra) */
export function putObject(area: StorageArea, name: string, bytes: Buffer): Promise<void> {
  assertName(name);
  return drivers[storageDriver()].put(area, name, bytes);
}

/** Đọc file; null nếu không có */
export function getObject(area: StorageArea, name: string): Promise<Buffer | null> {
  assertName(name);
  return drivers[storageDriver()].get(area, name);
}

/** Xóa file; không có thì bỏ qua */
export function removeObject(area: StorageArea, name: string) {
  assertName(name);
  return drivers[storageDriver()].remove(area, name);
}

/** Tên file trong một khu của ổ đĩa (để chép đi nơi khác); thư mục chưa có thì rỗng */
export async function listDiskObjects(area: StorageArea): Promise<string[]> {
  try {
    return (await readdir(path.dirname(diskPath(area, 'x')), { withFileTypes: true }))
      .filter((entry) => entry.isFile() && /^[A-Za-z0-9._-]+$/.test(entry.name) && !entry.name.startsWith('.'))
      .map((entry) => entry.name)
      .sort();
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
    throw error;
  }
}

/** Kiểm tra cấu hình lúc khởi động (hoặc trước khi chép lên Supabase) */
export function validateStorageEnvironment(driver: StorageDriver = storageDriver()) {
  if (driver === 'supabase') supabaseConfig();
}
