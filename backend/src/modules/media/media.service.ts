import { randomUUID } from 'node:crypto';
import { AppError } from '../../common/errors/app-error.js';
import { contentTypeOf, getObject, putObject, type StorageArea } from '../../services/storage.service.js';

/** Ảnh người dùng tải lên ngoài tin đăng: ảnh bài viết bảng tin, ảnh đại diện, poster shop. */
export const MEDIA_AREAS = { feed: 'feeds', avatar: 'avatars', poster: 'posters', shop: 'shops' } as const satisfies Record<string, StorageArea>;
export type MediaPurpose = keyof typeof MEDIA_AREAS;
type MediaArea = (typeof MEDIA_AREAS)[MediaPurpose];

export const MEDIA_PREFIX = '/api/v1/media/';
const MAX_BYTES = 5 * 1024 * 1024;

/** Tên file: "<userId>_<uuid>.<ext>" để biết ảnh của ai mà không cần bảng riêng.
 *  userId là UUID, hoặc id chữ-số-gạch ngang của tài khoản seed (VD shop-samsung). */
const NAME = /^[A-Za-z0-9-]{1,64}_[0-9a-f-]{36}\.(jpg|png|webp)$/;

export function mediaPurpose(value: unknown): MediaPurpose {
  if (value === undefined) return 'feed';
  if (typeof value === 'string' && value in MEDIA_AREAS) return value as MediaPurpose;
  throw new AppError(400, 'INVALID_PURPOSE', 'purpose must be feed, avatar or poster');
}

/** Đuôi file theo magic bytes; không phải JPEG/PNG/WebP thì 415 */
export function imageExtension(bytes: unknown): 'jpg' | 'png' | 'webp' {
  if (!Buffer.isBuffer(bytes) || !bytes.length) throw new AppError(415, 'INVALID_IMAGE', 'JPEG, PNG or WebP required');
  if (bytes.length > MAX_BYTES) throw new AppError(413, 'IMAGE_TOO_LARGE', 'Ảnh phải có dung lượng tối đa 5 MB.');
  if (bytes.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]))) return 'jpg';
  if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return 'png';
  if (bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP') return 'webp';
  throw new AppError(415, 'INVALID_IMAGE', 'JPEG, PNG or WebP required');
}

/** Lưu ảnh vào khu của [purpose], trả về đường dẫn tương đối để lưu vào database */
export async function uploadMedia(userId: string, purpose: MediaPurpose, bytes: unknown) {
  const name = `${userId}_${randomUUID()}.${imageExtension(bytes)}`;
  if (!NAME.test(name)) throw new AppError(400, 'INVALID_USER', 'Invalid user id');
  const area = MEDIA_AREAS[purpose];
  await putObject(area, name, bytes as Buffer);
  return `${MEDIA_PREFIX}${area}/${name}`;
}

/** Đường dẫn [url] có phải ảnh do /media tải lên vào khu của [purpose] không */
export function isMediaUrl(url: unknown, purpose: MediaPurpose): boolean {
  if (typeof url !== 'string' || !url.startsWith(`${MEDIA_PREFIX}${MEDIA_AREAS[purpose]}/`)) return false;
  return NAME.test(url.slice(`${MEDIA_PREFIX}${MEDIA_AREAS[purpose]}/`.length));
}

export async function readMedia(area: string, name: string) {
  if (!(Object.values(MEDIA_AREAS) as string[]).includes(area) || !NAME.test(name)) {
    throw new AppError(404, 'MEDIA_NOT_FOUND', 'Không tìm thấy ảnh.');
  }
  const bytes = await getObject(area as MediaArea, name);
  if (!bytes) throw new AppError(404, 'MEDIA_NOT_FOUND', 'Không tìm thấy ảnh.');
  return { bytes, contentType: contentTypeOf(name) };
}
