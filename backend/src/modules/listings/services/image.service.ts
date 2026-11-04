import { ListingStatus } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { hasPermission, PERMISSION } from '../../../common/auth/permissions.js';
import { AppError } from '../../../common/errors/app-error.js';
import type { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { contentTypeOf, getObject, putObject, removeObject } from '../../../services/storage.service.js';
import { IMAGE_EDITABLE, IMAGE_NAME, IMAGE_PREFIX, MAX_IMAGE_BYTES, MAX_IMAGES } from '../listing.type.js';
import { orderedImages } from '../listing.validator.js';
import * as listingRepository from '../repositories/listing.repository.js';

/** Ảnh tin nằm ở khu 'listings' của storage (ổ đĩa hoặc Supabase Storage, theo STORAGE_DRIVER) */
const AREA = 'listings';

/** Đuôi file theo Content-Type, kiểm tra cả byte đầu file. Dùng chung cho ảnh nội dung. */
export function imageExtension(contentType: unknown, bytes: unknown): string {
  if (!Buffer.isBuffer(bytes) || bytes.length === 0 || bytes.length > MAX_IMAGE_BYTES) {
    throw new AppError(400, 'INVALID_IMAGE', 'Ảnh phải có dung lượng tối đa 5 MB.');
  }
  const content = bytes as Buffer;
  if (contentType === 'image/jpeg' && content.length >= 3 && content[0] === 0xff && content[1] === 0xd8 && content[2] === 0xff) return 'jpg';
  if (contentType === 'image/png' && content.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return 'png';
  if (contentType === 'image/webp' && content.toString('ascii', 0, 4) === 'RIFF' && content.toString('ascii', 8, 12) === 'WEBP') return 'webp';
  throw new AppError(400, 'INVALID_IMAGE', 'Chỉ nhận ảnh JPEG, PNG hoặc WebP hợp lệ.');
}

/** Xóa file của các URL ảnh tin (bỏ qua URL lạ hoặc file đã mất) */
export async function removeStoredImages(urls: string[]) {
  for (const url of urls) {
    if (url.startsWith(IMAGE_PREFIX) && IMAGE_NAME.test(url.slice(IMAGE_PREFIX.length))) {
      await removeObject(AREA, url.slice(IMAGE_PREFIX.length)).catch(() => {});
    }
  }
}

async function requireImageEditable(ownerId: string, id: string) {
  const current = await listingRepository.findOwned(id, ownerId);
  if (!current) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
  if (!IMAGE_EDITABLE.includes(current.status)) throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Tin này không thể sửa ảnh.');
  return current;
}

/** Sau khi đổi ảnh: nháp vẫn là nháp, tin khác quay lại chờ duyệt */
const statusAfterImageChange = (status: ListingStatus) => status === ListingStatus.DRAFT ? ListingStatus.DRAFT : ListingStatus.PENDING;

/** Thêm một ảnh vào cuối danh sách ảnh của tin */
export async function addImage(ownerId: string, id: string, contentType: string | undefined, bytes: unknown) {
  const extension = imageExtension(contentType, bytes);
  const current = await requireImageEditable(ownerId, id);
  if (current.images.length >= MAX_IMAGES) throw new AppError(409, 'IMAGE_LIMIT', 'Mỗi tin được tối đa 20 ảnh.');
  const filename = `${randomUUID()}.${extension}`;
  try {
    await putObject(AREA, filename, bytes as Buffer);
    const url = `${IMAGE_PREFIX}${filename}`;
    const changed = await listingRepository.updateImagesIfUnchanged(id, ownerId, current,
      { images: [...current.images, url], status: statusAfterImageChange(current.status) });
    if (!changed) throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi. Vui lòng thử lại.');
    return { url };
  } catch (error) {
    await removeObject(AREA, filename).catch(() => {});
    throw error;
  }
}

/** Sắp xếp lại / bỏ bớt ảnh; file của ảnh bị bỏ được xóa */
export async function reorderImages(ownerId: string, id: string, body: unknown) {
  const current = await requireImageEditable(ownerId, id);
  const images = orderedImages(body, current.images);
  const changed = await listingRepository.updateImagesIfUnchanged(id, ownerId, current,
    { images, status: statusAfterImageChange(current.status) });
  if (!changed) throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi. Vui lòng thử lại.');
  await removeStoredImages(current.images.filter((item) => !images.includes(item)));
  return { images };
}

/**
 * Đọc file ảnh tin. Ai cũng xem được ảnh của tin đang hiển thị;
 * ảnh tin chưa hiển thị chỉ chủ tin và người kiểm duyệt xem được.
 */
export async function readImage(viewer: AuthRequest['user'], filename: string) {
  const notFound = () => new AppError(404, 'IMAGE_NOT_FOUND', 'Không tìm thấy ảnh.');
  if (!IMAGE_NAME.test(filename)) throw notFound();
  const listing = await listingRepository.findByImage(IMAGE_PREFIX + filename);
  if (!listing || !(hasPermission(viewer?.role, PERMISSION.LISTING_MODERATE) || viewer?.userId === listing.ownerId ||
    (listing.status === ListingStatus.AVAILABLE && listing.owner.status === 'ACTIVE'))) throw notFound();
  const bytes = await getObject(AREA, filename);
  if (!bytes) throw notFound();
  return { bytes, contentType: contentTypeOf(filename) };
}
