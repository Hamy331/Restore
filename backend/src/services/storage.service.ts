import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
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

/** Thư mục logic: listings = ảnh tin, admin = ảnh nội dung (bìa bài viết) */
export type StorageArea = 'listings' | 'admin';

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

async function supabaseRequest(method: string, objectPath: string, init: { body?: BodyInit; headers?: Record<string, string> } = {}) {
  const { url, key, bucket } = supabaseConfig();
  return fetch(`${url}/storage/v1/object/${bucket}${objectPath}`, {
    method,
    body: init.body,
    headers: { Authorization: `Bearer ${key}`, apikey: key, ...init.headers },
  });
}

/** Supabase trả 404, hoặc 400 kèm statusCode "404" / not_found, khi object không có */
async function isNotFound(response: Response) {
  if (response.status === 404) return true;
  if (response.status !== 400) return false;
  const body = await response.clone().text();
  return /not[_ ]found|"404"/i.test(body);
}

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
    if (!response.ok) throw await failure('upload', key, response);
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

const drivers = { disk, supabase } as const;

/* ---------- API dùng chung ---------- */

/** Lưu file mới; trùng tên thì lỗi (tên luôn là UUID nên không xảy ra) */
export function putObject(area: StorageArea, name: string, bytes: Buffer) {
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

/** Kiểm tra cấu hình lúc khởi động */
export function validateStorageEnvironment() {
  if (storageDriver() === 'supabase') supabaseConfig();
}
