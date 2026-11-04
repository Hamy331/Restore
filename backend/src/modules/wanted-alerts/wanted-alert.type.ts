import type { WantedAlertMatchLevel } from './wanted-alert.matcher.js';

export const MATCH_LEVELS: readonly WantedAlertMatchLevel[] = ['BROAD', 'BALANCED', 'STRICT'];

/** Kiểu giao dịch người mua chấp nhận, khớp cột allowSale / allowExchange của Listing */
export const DEAL_TYPES = ['buy', 'exchange'] as const;
export type DealType = (typeof DEAL_TYPES)[number];

export const AREA_LEVELS = ['province', 'ward'] as const;
export type AreaLevel = (typeof AREA_LEVELS)[number];

/** Số thông báo tối đa của một người */
export const MAX_ALERTS_PER_USER = 20;

/** Độ dài mô tả món cần tìm (khớp WantedAlertDraft trong app) */
export const KEYWORDS_MIN = 2;
export const KEYWORDS_MAX = 80;

/** Giá VND lớn nhất (12 chữ số, như giá tin đăng) */
export const MAX_PRICE = 999_999_999_999;

/** Xem trước chấm điểm trên tối đa bấy nhiêu tin mới nhất đã qua bộ lọc */
export const PREVIEW_CANDIDATES = 300;

/** Số ảnh bìa tin khớp gần nhất trả kèm mỗi thông báo */
export const PREVIEW_IMAGES = 3;
