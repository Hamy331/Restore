/** Ảnh nội dung (bìa bài viết), lưu trên ổ đĩa; chuyển sang Supabase Storage ở C24 */
export const MEDIA_PREFIX = '/api/v1/content/media/';
export const MEDIA_NAME = /^[0-9a-f-]{36}\.(jpg|png|webp)$/;

/** Số bản ghi mỗi trang ở các danh sách nội dung */
export const PAGE_SIZE = 20;

/** Đối tượng có thể bị báo cáo */
export const REPORT_TARGETS = ['LISTING', 'USER'] as const;
export type ReportTarget = (typeof REPORT_TARGETS)[number];
