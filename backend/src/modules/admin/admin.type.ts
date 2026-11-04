/** Hành động của admin trên tài khoản thành viên */
export const USER_ACTIONS = ['WARN', 'SUSPEND', 'BAN', 'RESTORE'] as const;
export type UserAction = (typeof USER_ACTIONS)[number];

/** Số ngày tạm khóa mặc định khi SUSPEND không gửi days */
export const DEFAULT_SUSPEND_DAYS = 7;

/** Số dòng nhật ký mới nhất hiện trên dashboard */
export const DASHBOARD_LOG_COUNT = 10;
