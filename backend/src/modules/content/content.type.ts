/** Ảnh nội dung (bìa bài viết), lưu qua services/storage.service (ổ đĩa hoặc Supabase Storage) */
export const MEDIA_PREFIX = '/api/v1/content/media/';
export const MEDIA_NAME = /^[0-9a-f-]{36}\.(jpg|png|webp)$/;

/** Số bản ghi mỗi trang ở các danh sách nội dung phía người dùng (trang quản trị dùng ADMIN_PAGE_SIZE = 25) */
export const PAGE_SIZE = 20;

/** Đối tượng có thể bị báo cáo từ ứng dụng người dùng */
export const REPORT_TARGETS = ['LISTING', 'USER', 'FEED_POST'] as const;
export type ReportTarget = (typeof REPORT_TARGETS)[number];

export const POST_STATUSES = ['DRAFT', 'PUBLISHED', 'HIDDEN', 'ARCHIVED'] as const;
export const TICKET_STATUSES = ['OPEN', 'RESOLVED'] as const;
export const REPORT_STATUSES = ['OPEN', 'RESOLVED', 'DISMISSED'] as const;

/** Cách xử lý báo cáo. Báo cáo tin: DISMISS, KEEP, REMOVE. Báo cáo thành viên: DISMISS, WARN, SUSPEND, BAN. */
export const REPORT_ACTIONS = ['DISMISS', 'KEEP', 'REMOVE', 'WARN', 'SUSPEND', 'BAN'] as const;
export type ReportAction = (typeof REPORT_ACTIONS)[number];
export const LISTING_REPORT_ACTIONS: readonly ReportAction[] = ['DISMISS', 'KEEP', 'REMOVE'];
export const USER_REPORT_ACTIONS: readonly ReportAction[] = ['DISMISS', 'WARN', 'SUSPEND', 'BAN'];
export const FEED_POST_REPORT_ACTIONS: readonly ReportAction[] = ['DISMISS', 'REMOVE'];
