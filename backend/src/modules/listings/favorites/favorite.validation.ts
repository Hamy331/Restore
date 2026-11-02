import { idParam, pageQuery } from '../../../common/validation/schemas.js';

/** Params `:id` = mã tin */
export const listingIdParams = idParam(64);

/** Query của GET /favorites: page, limit 1–100 (mặc định 20) */
export const favoritesQuery = pageQuery({ defaultLimit: 20, maxLimit: 100 });
