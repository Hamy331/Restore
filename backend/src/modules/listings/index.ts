import { Router } from 'express';
import draftRouter from './routes/draft.route.js';
import favoriteRouter from './routes/favorite.route.js';
import feedRouter from './routes/feed.route.js';
import imageRouter from './routes/image.route.js';
import listingRouter from './routes/listing.route.js';
import moderationRouter from './routes/moderation.route.js';

/**
 * Toàn bộ API /api/v1/listings. Thứ tự mount quan trọng: các đường dẫn một đoạn
 * (/recommended, /favorites, /summary, /mine) phải đứng trước GET /:id trong listingRouter.
 */
export const listingsRouter = Router();
listingsRouter.use(feedRouter);
listingsRouter.use(favoriteRouter);
listingsRouter.use(draftRouter);
listingsRouter.use(imageRouter);
listingsRouter.use(moderationRouter);
listingsRouter.use(listingRouter);

export { imageExtension } from './services/image.service.js';
export { listingSelect, toFeedItemDto } from './listing.dto.js';
export type { ListingDto, ListingRecord } from './listing.dto.js';
export { onListingApproved } from './services/approval-hooks.js';
export type { ListingApprovedHook } from './services/approval-hooks.js';
export { default as listingsAdminRouter } from './routes/admin-listing.route.js';
export { getAdminListing, moderate } from './services/moderation.service.js';
