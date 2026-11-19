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

/** Ảnh chỉ bản sửa dùng (tin đang hiển thị không dùng), để xóa file khi bỏ bản sửa */
export const revisionOnlyImages = (revisionImages: string[], listingImages: string[]) =>
  revisionImages.filter((url) => !listingImages.includes(url));

/** Tin đã duyệt: ảnh sửa vào bản sửa chờ duyệt, tin vẫn giữ ảnh cũ */
const REVISABLE: readonly ListingStatus[] = [ListingStatus.AVAILABLE, ListingStatus.HIDDEN];

/**
 * Bộ ảnh đang sửa: tin đã duyệt thì là ảnh của bản sửa (phải gửi nội dung sửa qua PUT /:id trước,
 * nếu không 409 EDIT_NOT_STARTED), tin khác là ảnh của tin.
 */
async function requireImageEditable(ownerId: string, id: string) {
  const current = await listingRepository.findOwned(id, ownerId);
  if (!current) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
  if (!IMAGE_EDITABLE.includes(current.status)) throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Tin này không thể sửa ảnh.');
  if (!REVISABLE.includes(current.status)) return { current, images: current.images, revision: false };
  if (!current.revision) {
    throw new AppError(409, 'EDIT_NOT_STARTED', 'Tin đã duyệt: gửi nội dung sửa trước rồi mới đổi ảnh.');
  }
  return { current, images: current.revision.images, revision: true };
}

/** Sau khi đổi ảnh: nháp vẫn là nháp, tin khác quay lại chờ duyệt */
const statusAfterImageChange = (status: ListingStatus) => status === ListingStatus.DRAFT ? ListingStatus.DRAFT : ListingStatus.PENDING;

/** Lưu bộ ảnh mới vào tin hoặc bản sửa khi chưa ai đổi từ lúc đọc; 409 LISTING_CHANGED nếu đã đổi */
async function saveImages(ownerId: string, id: string, editable: Awaited<ReturnType<typeof requireImageEditable>>, images: string[]) {
  const { current } = editable;
  const changed = editable.revision
    ? await listingRepository.updateRevisionImagesIfUnchanged(id, editable.images, images)
    : await listingRepository.updateImagesIfUnchanged(id, ownerId, current, { images, status: statusAfterImageChange(current.status) });
  if (!changed) throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi. Vui lòng thử lại.');
}

/** Thêm một ảnh vào cuối danh sách ảnh của tin (tin đã duyệt: của bản sửa) */
export async function addImage(ownerId: string, id: string, contentType: string | undefined, bytes: unknown) {
  const extension = imageExtension(contentType, bytes);
  const editable = await requireImageEditable(ownerId, id);
  if (editable.images.length >= MAX_IMAGES) throw new AppError(409, 'IMAGE_LIMIT', 'Mỗi tin được tối đa 20 ảnh.');
  const filename = `${randomUUID()}.${extension}`;
  try {
    await putObject(AREA, filename, bytes as Buffer);
    const url = `${IMAGE_PREFIX}${filename}`;
    await saveImages(ownerId, id, editable, [...editable.images, url]);
    return { url };
  } catch (error) {
    await removeObject(AREA, filename).catch(() => {});
    throw error;
  }
}

/**
 * Sắp xếp lại / bỏ bớt ảnh; file của ảnh bị bỏ được xóa.
 * Tin đã duyệt: đổi ảnh của bản sửa, ảnh tin đang hiển thị còn dùng thì giữ file.
 */
export async function reorderImages(ownerId: string, id: string, body: unknown) {
  const editable = await requireImageEditable(ownerId, id);
  const images = orderedImages(body, editable.images);
  await saveImages(ownerId, id, editable, images);
  const dropped = editable.images.filter((item) => !images.includes(item));
  await removeStoredImages(editable.revision ? revisionOnlyImages(dropped, editable.current.images) : dropped);
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
  const moderator = hasPermission(viewer?.role, PERMISSION.LISTING_MODERATE);
  if (listing) {
    if (!(moderator || viewer?.userId === listing.ownerId ||
      (listing.status === ListingStatus.AVAILABLE && listing.owner.status === 'ACTIVE'))) throw notFound();
  } else {
    // Ảnh mới của bản sửa chưa duyệt: chỉ chủ tin và người duyệt xem được
    const edited = await listingRepository.findByRevisionImage(IMAGE_PREFIX + filename);
    if (!edited || !(moderator || viewer?.userId === edited.ownerId)) throw notFound();
  }
  const bytes = await getObject(AREA, filename);
  if (!bytes) throw notFound();
  return { bytes, contentType: contentTypeOf(filename) };
}
