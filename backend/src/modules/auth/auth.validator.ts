import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { EMAIL_PATTERN, MAX_EMAIL_LENGTH, OTP_PATTERN, STRONG_PASSWORD_PATTERN, USERNAME_PATTERN } from './auth.type.js';

/*
 * Đầu vào của /auth. Lỗi trả 422 với mã riêng từng trường (INVALID_EMAIL, WEAK_PASSWORD...) mà app đang đọc.
 * Trường được kiểm tra theo thứ tự khai báo; trường đầu tiên sai quyết định lỗi trả về.
 * Body không phải object (hoặc thiếu) coi như mọi trường đều thiếu.
 */

const asString = (value: unknown): string => (typeof value === 'string' ? value.trim() : '');

/** Đọc body như req.body?.field: không phải object thì mọi trường là undefined */
const fieldsOf = (body: unknown) => (body ?? {}) as Record<string, unknown>;

/* ---------- Từng trường ---------- */

export const email = (value: unknown): string => {
  const result = asString(value).toLowerCase();
  if (!EMAIL_PATTERN.test(result) || result.length > MAX_EMAIL_LENGTH) {
    throw new AppError(422, 'INVALID_EMAIL', 'Email chưa đúng định dạng.', 'email');
  }
  return result;
};

/** Mật khẩu mới (đăng ký, đặt lại); không trim */
export const strongPassword = (value: unknown, field = 'password'): string => {
  const password = typeof value === 'string' ? value : '';
  if (!STRONG_PASSWORD_PATTERN.test(password)) {
    throw new AppError(422, 'WEAK_PASSWORD', 'Mật khẩu phải có 8-72 ký tự, gồm chữ hoa, chữ thường và chữ số.', field);
  }
  return password;
};

/** Mật khẩu khi đăng nhập: chỉ cần có */
export const loginPassword = (value: unknown): string => {
  const password = typeof value === 'string' ? value : '';
  if (!password) throw new AppError(422, 'PASSWORD_REQUIRED', 'Vui lòng nhập mật khẩu.', 'password');
  return password;
};

export const username = (value: unknown): string => {
  const result = asString(value).toLowerCase();
  if (!USERNAME_PATTERN.test(result)) {
    throw new AppError(422, 'INVALID_USERNAME',
      'Tên người dùng phải có 3-30 ký tự và chỉ gồm chữ thường, số, dấu chấm hoặc gạch dưới.', 'username');
  }
  return result;
};

/** Họ tên 2-80 ký tự, gộp khoảng trắng thừa */
export const fullName = (value: unknown): string => {
  const result = asString(value).replace(/\s+/g, ' ');
  if (result.length < 2 || result.length > 80) {
    throw new AppError(422, 'INVALID_FULL_NAME', 'Họ tên phải có từ 2 đến 80 ký tự.', 'fullName');
  }
  return result;
};

export const otp = (value: unknown): string => {
  const result = asString(value);
  if (!OTP_PATTERN.test(result)) throw new AppError(422, 'INVALID_OTP_FORMAT', 'Mã OTP phải gồm đúng 6 chữ số.', 'otp');
  return result;
};

/** Refresh token / reset token: chuỗi không rỗng */
export const token = (value: unknown, field: string): string => {
  const result = asString(value);
  if (!result) throw new AppError(422, 'TOKEN_REQUIRED', 'Phiên xác thực không hợp lệ.', field);
  return result;
};

/* ---------- Body từng API ---------- */

/** POST /auth/login */
export const loginBody = z.unknown().transform((body) => {
  const b = fieldsOf(body);
  return { email: email(b.email), password: loginPassword(b.password) };
});

/** POST /auth/register */
export const registerBody = z.unknown().transform((body) => {
  const b = fieldsOf(body);
  return { email: email(b.email), password: strongPassword(b.password), username: username(b.username), fullName: fullName(b.fullName) };
});

/** POST /auth/resend-registration-otp, /auth/forgot-password */
export const emailBody = z.unknown().transform((body) => ({ email: email(fieldsOf(body).email) }));

/** POST /auth/verify-registration-otp, /auth/verify-otp */
export const otpBody = z.unknown().transform((body) => {
  const b = fieldsOf(body);
  return { email: email(b.email), otp: otp(b.otp) };
});

/** POST /auth/reset-password */
export const resetPasswordBody = z.unknown().transform((body) => {
  const b = fieldsOf(body);
  return { resetToken: token(b.resetToken, 'resetToken'), newPassword: strongPassword(b.newPassword, 'newPassword') };
});

/** POST /auth/refresh, /auth/logout */
export const refreshTokenBody = z.unknown().transform((body) => ({ refreshToken: token(fieldsOf(body).refreshToken, 'refreshToken') }));
