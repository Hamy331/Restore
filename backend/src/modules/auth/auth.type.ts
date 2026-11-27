/** Email: có @ và dấu chấm sau @, tối đa 254 ký tự (đã trim, chữ thường) */
export const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
export const MAX_EMAIL_LENGTH = 254;

/**
 * Tên người dùng: 3-30 ký tự a-z, 0-9, dấu chấm, gạch dưới; có ít nhất một chữ cái;
 * dấu chấm không đứng đầu, cuối hoặc hai dấu liền nhau
 */
export const USERNAME_PATTERN = /^(?=.{3,30}$)(?=.*[a-z])(?!\.)(?!.*\.$)(?!.*\.\.)[a-z0-9._]+$/;

/** Đổi tên người dùng xong phải chờ chừng này ngày mới đổi tiếp (link `/u/@tên` cũ không bị chiếm ngay) */
export const USERNAME_CHANGE_COOLDOWN_DAYS = 14;

/** Mật khẩu mới: 8-72 ký tự, có chữ hoa, chữ thường, chữ số (bcrypt chỉ dùng 72 byte đầu) */
export const STRONG_PASSWORD_PATTERN = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,72}$/;

/** Mã OTP gồm đúng 6 chữ số */
export const OTP_PATTERN = /^\d{6}$/;
