import { ListingStatus } from '@prisma/client';
import type { listingFilters } from './listing.validator.js';

/** Bộ lọc danh sách tin trang chủ */
export const FEED_FILTERS = ['newest', 'nearby', 'exchange'] as const;
export type FeedFilter = (typeof FEED_FILTERS)[number];

/** Bộ lọc tìm kiếm đã làm sạch */
export type ListingFilters = ReturnType<typeof listingFilters>;

/** Trạng thái chủ tin được tự đổi sang */
export const OWNER_STATUS_TARGETS: readonly ListingStatus[] = [
  ListingStatus.AVAILABLE, ListingStatus.HIDDEN, ListingStatus.SOLD, ListingStatus.EXCHANGED,
];

/** Trạng thái còn sửa được nội dung nháp */
export const DRAFT_EDITABLE: readonly ListingStatus[] = [
  ListingStatus.DRAFT, ListingStatus.PENDING, ListingStatus.REJECTED, ListingStatus.AVAILABLE, ListingStatus.HIDDEN,
];

/** Trạng thái còn sửa được tin đã đăng (PUT /:id) */
export const LISTING_EDITABLE: readonly ListingStatus[] = [
  ListingStatus.AVAILABLE, ListingStatus.HIDDEN, ListingStatus.REJECTED, ListingStatus.PENDING,
];

/** Trạng thái còn sửa được ảnh */
export const IMAGE_EDITABLE: readonly ListingStatus[] = [
  ListingStatus.AVAILABLE, ListingStatus.HIDDEN, ListingStatus.DRAFT, ListingStatus.PENDING, ListingStatus.REJECTED,
];

/** Ảnh tin đăng (lưu trên ổ đĩa, chuyển sang Supabase Storage ở C24) */
export const IMAGE_PREFIX = '/api/v1/listings/media/';
export const MAX_IMAGES = 20;
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const IMAGE_NAME = /^[0-9a-f-]{36}\.(jpg|png|webp)$/;

/** Quyết định của admin trên một tin: duyệt / từ chối / yêu cầu sửa khi PENDING, gỡ khi AVAILABLE */
export const MODERATION_ACTIONS = ['APPROVE', 'REJECT', 'REQUEST_CHANGES', 'REMOVE'] as const;
export type ModerationAction = (typeof MODERATION_ACTIONS)[number];
