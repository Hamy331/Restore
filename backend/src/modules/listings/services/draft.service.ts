import { ListingStatus } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { withQuotaTransaction } from '../../stores/store.service.js';
import { DraftInput, toOwnerListingDto } from '../listing.dto.js';
import { DRAFT_EDITABLE } from '../listing.type.js';
import { createInput, validateAttributes } from '../listing.validator.js';
import * as listingRepository from '../repositories/listing.repository.js';
import { removeStoredImages } from './image.service.js';
import { assertPublishable, assertQuota, requireOwnedListing, updateOwnedListing } from './listing.service.js';

/** Lưu nháp mới; danh mục nếu có phải tồn tại */
export async function createDraft(ownerId: string, data: DraftInput) {
  if (data.categoryId && !await listingRepository.findCategory(data.categoryId)) {
    throw new AppError(400, 'INVALID_DRAFT', 'Danh mục không tồn tại.', 'categoryId');
  }
  const listing = await listingRepository.createListing({ ...data, ownerId, status: ListingStatus.DRAFT, images: [] });
  return toOwnerListingDto(listing);
}

/** Sửa nháp, hoặc đưa tin đã đăng về nháp để sửa tiếp */
export async function updateDraft(ownerId: string, id: string, data: DraftInput) {
  const listing = await listingRepository.transaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if (!DRAFT_EDITABLE.includes(current.status)) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn sửa được.');
    if (data.categoryId && !await listingRepository.findActiveCategory(tx, data.categoryId)) {
      throw new AppError(400, 'INVALID_DRAFT', 'Danh mục không tồn tại.', 'categoryId');
    }
    const category = data.categoryId ? await listingRepository.findCategory(data.categoryId, tx) : null;
    if (category) validateAttributes(data.attributes, category.metadata, false);
    await updateOwnedListing(tx, id, ownerId, current.status, { ...data, status: ListingStatus.DRAFT, reviewReason: null });
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/** Đăng nháp: kiểm tra đủ nội dung như tin mới, cần ít nhất một ảnh, trừ lượt đăng */
export async function publishDraft(ownerId: string, id: string) {
  const listing = await withQuotaTransaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if (current.status === ListingStatus.PENDING) return listingRepository.findSelected(tx, id);
    if (current.status !== ListingStatus.DRAFT) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn là bản nháp.');
    if (!current.images.length) throw new AppError(400, 'INVALID_LISTING', 'Cần ít nhất một ảnh để đăng tin.', 'images');
    const location = current.location as Record<string, unknown> | null;
    const data = createInput({
      title: current.title, description: current.description,
      price: current.price.toString(), condition: current.condition,
      categoryId: current.categoryId, isNegotiable: current.isNegotiable,
      allowSale: current.allowSale, allowExchange: current.allowExchange,
      exchangeWish: current.exchangeWish, sellerType: current.sellerType, attributes: current.attributes,
      location: location
        ? Object.fromEntries(['provinceCode', 'wardCode', 'streetAddress', 'latitude', 'longitude', 'geoSource'].map((key) => [key, location[key]]))
        : null,
    });
    await assertPublishable(tx, data);
    const now = new Date();
    await assertQuota(tx, ownerId, now, { daily: true });
    await updateOwnedListing(tx, id, ownerId, ListingStatus.DRAFT, { status: ListingStatus.PENDING, publishedAt: now });
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/** Xóa nháp và ảnh của nó */
export async function deleteDraft(ownerId: string, id: string) {
  const current = await listingRepository.findOwnedDraft(id, ownerId);
  if (!current) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy bản nháp của bạn.');
  if (!await listingRepository.deleteOwnedDraft(id, ownerId)) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn là bản nháp.');
  await removeStoredImages(current.images);
}
