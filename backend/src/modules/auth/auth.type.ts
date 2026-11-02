/** Email: có @ và dấu chấm sau @, tối đa 254 ký tự (đã trim, chữ thường) */
export const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
export const MAX_EMAIL_LENGTH = 254;

/** Tên người dùng: 3-30 ký tự a-z, 0-9, dấu chấm, gạch dưới */
export const USERNAME_PATTERN = /^[a-z0-9._]{3,30}$/;

/** Mật khẩu mới: 8-72 ký tự, có chữ hoa, chữ thường, chữ số (bcrypt chỉ dùng 72 byte đầu) */
export const STRONG_PASSWORD_PATTERN = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,72}$/;

/** Mã OTP gồm đúng 6 chữ số */
export const OTP_PATTERN = /^\d{6}$/;
