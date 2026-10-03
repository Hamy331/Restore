import { AppError } from '../../errors/app-error.js';

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const usernamePattern = /^[a-z0-9._]{3,30}$/;
const strongPasswordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,72}$/;
const asString = (value: unknown): string =>
  typeof value === 'string' ? value.trim() : '';

export const parseEmail = (value: unknown): string => {
  const email = asString(value).toLowerCase();
  if (!emailPattern.test(email) || email.length > 254) {
    throw new AppError(422, 'INVALID_EMAIL', 'Email chưa đúng định dạng.', 'email');
  }
  return email;
};

export const parsePassword = (value: unknown, field = 'password'): string => {
  const password = typeof value === 'string' ? value : '';
  if (!strongPasswordPattern.test(password)) {
    throw new AppError(
      422,
      'WEAK_PASSWORD',
      'Mật khẩu phải có 8-72 ký tự, gồm chữ hoa, chữ thường và chữ số.',
      field,
    );
  }
  return password;
};

export const parseLoginPassword = (value: unknown): string => {
  const password = typeof value === 'string' ? value : '';
  if (!password) {
    throw new AppError(422, 'PASSWORD_REQUIRED', 'Vui lòng nhập mật khẩu.', 'password');
  }
  return password;
};

export const parseUsername = (value: unknown): string => {
  const username = asString(value).toLowerCase();
  if (!usernamePattern.test(username)) {
    throw new AppError(
      422,
      'INVALID_USERNAME',
      'Tên người dùng phải có 3-30 ký tự và chỉ gồm chữ thường, số, dấu chấm hoặc gạch dưới.',
      'username',
    );
  }
  return username;
};

export const parseFullName = (value: unknown): string => {
  const fullName = asString(value).replace(/\s+/g, ' ');
  if (fullName.length < 2 || fullName.length > 80) {
    throw new AppError(422, 'INVALID_FULL_NAME', 'Họ tên phải có từ 2 đến 80 ký tự.', 'fullName');
  }
  return fullName;
};

export const parseOtp = (value: unknown): string => {
  const otp = asString(value);
  if (!/^\d{6}$/.test(otp)) {
    throw new AppError(422, 'INVALID_OTP_FORMAT', 'Mã OTP phải gồm đúng 6 chữ số.', 'otp');
  }
  return otp;
};

export const parseToken = (value: unknown, field: string): string => {
  const token = asString(value);
  if (!token) {
    throw new AppError(422, 'TOKEN_REQUIRED', 'Phiên xác thực không hợp lệ.', field);
  }
  return token;
};
