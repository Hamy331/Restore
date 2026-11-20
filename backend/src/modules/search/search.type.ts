/** Số từ khoá tối đa giữ trong lịch sử mỗi người */
export const HISTORY_LIMIT = 10;

/** Số từ khoá "Tìm nhiều" trả về */
export const TRENDING_LIMIT = 8;

/** "Tìm nhiều" tính trên các lượt tìm trong ngần ấy ngày gần nhất */
export const TRENDING_DAYS = 7;

/**
 * Từ khoá trong lịch sử chỉ được gợi ý cho người khác ("Tìm nhiều", gợi ý khi gõ) khi có ít nhất
 * ngần ấy người cùng tìm, để không lộ từ khoá riêng của một người (tên, số điện thoại...)
 */
export const MIN_SHARED_USERS = 2;

/** Cần ít nhất ngần ấy từ khoá "Tìm nhiều" thật, thiếu thì bù bằng tên chuyên mục */
export const TRENDING_MIN = 3;
