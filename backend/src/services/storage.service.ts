import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { Readable } from 'node:stream';
import { v2 as cloudinary, type UploadApiOptions } from 'cloudinary';

/**
 * Lưu file người dùng tải lên. Hai driver, chọn bằng STORAGE_DRIVER:
 *  - disk (mặc định, máy dev / test): <STORAGE_DISK_ROOT | ./uploads>/<area>/<name>
 *  - cloudinary: asset <CLOUDINARY_ROOT_FOLDER | media>/<area>/<tên không đuôi>, cấu hình bằng CLOUDINARY_URL.
 *    Khu công khai (bảng tin, avatar, shop, poster) để kiểu "upload"; khu cần kiểm quyền để kiểu
 *    "authenticated" (URL phải có chữ ký do server tạo).
 *
 * Module nghiệp vụ chỉ gọi putObject / getObject / removeObject / deliveryUrl, không biết file nằm ở đâu.
 * Đọc ảnh: có deliveryUrl (Cloudinary) thì route chuyển hướng sang CDN, VPS không phải gửi byte ảnh;
 * không có (disk) thì route tự gửi file.
 */

/** Thư mục logic: listings = ảnh tin, admin = ảnh nội dung, feeds = ảnh bảng tin, avatars = ảnh đại diện,
 *  posters = poster shop, shops = logo / ảnh bìa shop, verifications = giấy tờ xác minh, chat = tệp trong chat */
export type StorageArea = 'listings' | 'admin' | 'feeds' | 'avatars' | 'posters' | 'shops' | 'verifications' | 'chat';

export const STORAGE_DRIVERS = ['disk', 'cloudinary'] as const;
export type StorageDriver = (typeof STORAGE_DRIVERS)[number];

/** Khu ai cũng xem được: URL CDN không cần chữ ký */
const PUBLIC_AREAS: readonly StorageArea[] = ['feeds', 'avatars', 'posters', 'shops'];

const CONTENT_TYPES: Record<string, string> = { '.mp4': 'video/mp4', '.mov': 'video/quicktime', '.webm': 'video/webm', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' };

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

/** Lỗi "đã có file", cùng mã EEXIST cho mọi driver */
const alreadyExists = (key: string) => Object.assign(new Error(`Storage object already exists: ${key}`), { code: 'EEXIST' });

/* ---------- Cỡ ảnh thu nhỏ ---------- */

/** Các cỡ ảnh thu nhỏ app xin qua `?w=` (frontend: media_url.dart) */
export const THUMB_WIDTHS = [240, 480, 960] as const;
export type ThumbWidth = (typeof THUMB_WIDTHS)[number];

/** `?w=` → cỡ nhỏ nhất đủ rộng; không gửi, sai hoặc lớn hơn 960 thì null (ảnh gốc) */
export function thumbWidth(value: unknown): ThumbWidth | null {
  const raw = Array.isArray(value) ? value[0] : value;
  if (typeof raw !== 'string' || !/^\d{1,5}$/.test(raw)) return null;
  const width = Number(raw);
  if (width <= 0) return null;
  return THUMB_WIDTHS.find((size) => size >= width) ?? null;
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
  url: (): string | null => null,
};

/* ---------- Cloudinary ---------- */

let configuredFrom: string | null = null;

/** Cấu hình SDK từ CLOUDINARY_URL = cloudinary://<api_key>:<api_secret>@<cloud_name> */
function cloudinaryReady() {
  const raw = process.env.CLOUDINARY_URL?.trim();
  if (!raw) throw new Error('STORAGE_DRIVER=cloudinary needs CLOUDINARY_URL.');
  if (configuredFrom !== raw) {
    let url: URL;
    try {
      url = new URL(raw);
    } catch {
      throw new Error('CLOUDINARY_URL must look like cloudinary://<api_key>:<api_secret>@<cloud_name>.');
    }
    if (url.protocol !== 'cloudinary:' || !url.hostname || !url.username || !url.password) {
      throw new Error('CLOUDINARY_URL must look like cloudinary://<api_key>:<api_secret>@<cloud_name>.');
    }
    cloudinary.config({
      cloud_name: url.hostname, api_key: decodeURIComponent(url.username),
      api_secret: decodeURIComponent(url.password), secure: true, analytics: false,
    });
    configuredFrom = raw;
  }
  return cloudinary;
}

/** Vị trí asset của file <area>/<name> trên Cloudinary */
function asset(area: StorageArea, name: string) {
  const { name: base, ext } = path.parse(name);
  const root = process.env.CLOUDINARY_ROOT_FOLDER?.trim() || 'media';
  return {
    publicId: `${root}/${area}/${base}`,
    folder: `${root}/${area}`,
    format: ext.slice(1).toLowerCase(),
    resourceType: contentTypeOf(name).startsWith('video/') ? 'video' as const : 'image' as const,
    type: PUBLIC_AREAS.includes(area) ? 'upload' as const : 'authenticated' as const,
  };
}

/** Ảnh lưu tối đa 2000px cạnh dài; Cloudinary mã hoá lại nên bỏ luôn EXIF / GPS của ảnh gốc */
const IMAGE_INCOMING = [{ width: 2000, height: 2000, crop: 'limit' }];

const cloud = {
  async put(area: StorageArea, name: string, bytes: Buffer) {
    const a = asset(area, name);
    const options: UploadApiOptions = {
      public_id: a.publicId, asset_folder: a.folder, resource_type: a.resourceType, type: a.type,
      overwrite: false, unique_filename: false, use_filename: false,
      ...(a.resourceType === 'image' ? { transformation: IMAGE_INCOMING } : {}),
    };
    const result = await new Promise<Record<string, unknown>>((resolve, reject) => {
      const upload = cloudinaryReady().uploader.upload_stream(options, (error, response) =>
        error || !response ? reject(error ?? new Error('Cloudinary upload failed')) : resolve(response as Record<string, unknown>));
      Readable.from(bytes).pipe(upload);
    });
    if (result.existing === true) throw alreadyExists(`${area}/${name}`);
  },
  async get(area: StorageArea, name: string) {
    const response = await fetch(cloud.originalUrl(area, name));
    if (response.status === 404) return null;
    if (!response.ok) throw new Error(`Cloudinary download ${area}/${name} failed: ${response.status}`);
    return Buffer.from(await response.arrayBuffer());
  },
  async remove(area: StorageArea, name: string) {
    const a = asset(area, name);
    const result = await cloudinaryReady().uploader.destroy(a.publicId, {
      resource_type: a.resourceType, type: a.type, invalidate: true,
    }) as { result?: string };
    if (result.result !== 'ok' && result.result !== 'not found') {
      throw new Error(`Cloudinary delete ${area}/${name} failed: ${result.result}`);
    }
  },
  originalUrl: (area: StorageArea, name: string) => cloud.url(area, name, null),
  /** URL CDN; có [width] thì là bản thu nhỏ (định dạng / chất lượng tự chọn theo trình duyệt) */
  url(area: StorageArea, name: string, width: ThumbWidth | null) {
    const a = asset(area, name);
    return cloudinaryReady().url(a.publicId, {
      resource_type: a.resourceType, type: a.type, format: a.format, sign_url: a.type === 'authenticated', secure: true,
      ...(width && a.resourceType === 'image'
        ? { transformation: [{ width, crop: 'limit', fetch_format: 'auto', quality: 'auto' }] }
        : {}),
    });
  },
};

/* ---------- API dùng chung ---------- */

const driver = () => (storageDriver() === 'cloudinary' ? cloud : disk);

/** Lưu file mới; trùng tên thì lỗi code EEXIST (tên luôn là UUID nên thực tế không xảy ra) */
export function putObject(area: StorageArea, name: string, bytes: Buffer): Promise<void> {
  assertName(name);
  return driver().put(area, name, bytes);
}

/** Đọc file; null nếu không có */
export function getObject(area: StorageArea, name: string): Promise<Buffer | null> {
  assertName(name);
  return driver().get(area, name);
}

/** Xóa file; không có thì bỏ qua */
export function removeObject(area: StorageArea, name: string) {
  assertName(name);
  return driver().remove(area, name);
}

/**
 * URL CDN để chuyển hướng tới (đã kiểm quyền xong), [width] là cỡ thu nhỏ; null khi driver không có CDN (disk).
 * Khu "authenticated" có chữ ký nên không tự đổi được cỡ / định dạng.
 */
export function deliveryUrl(area: StorageArea, name: string, width: ThumbWidth | null = null): string | null {
  assertName(name);
  return driver().url(area, name, width);
}

/** Kiểm tra cấu hình lúc khởi động */
export function validateStorageEnvironment(current: StorageDriver = storageDriver()) {
  if (current === 'cloudinary') cloudinaryReady();
}

/** File đọc để trả cho app: URL CDN để chuyển hướng tới, hoặc byte file (driver disk) */
export type StoredFile = { url: string } | { bytes: Buffer; contentType: string };

/** Đọc file để trả cho app (đã kiểm quyền xong); null nếu không có */
export async function readStored(area: StorageArea, name: string, width: ThumbWidth | null = null): Promise<StoredFile | null> {
  const url = deliveryUrl(area, name, width);
  if (url) return { url };
  const bytes = await getObject(area, name);
  return bytes ? { bytes, contentType: contentTypeOf(name) } : null;
}
