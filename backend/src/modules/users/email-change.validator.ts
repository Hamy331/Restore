import { z } from 'zod';
import { email, loginPassword, otp } from '../auth/auth.validator.js';

const fieldsOf = (body: unknown) => (body ?? {}) as Record<string, unknown>;

/**
 * POST /users/me/email: email mới (khoá `email` để rate limit gửi OTP đếm theo
 * email) và mật khẩu hiện tại. Tài khoản không có mật khẩu thì gửi chuỗi rỗng.
 */
export const emailChangeBody = z.unknown().transform((body) => {
  const b = fieldsOf(body);
  return {
    email: email(b.email),
    password: typeof b.password === 'string' && b.password ? loginPassword(b.password) : '',
  };
});

/** POST /users/me/email/verify */
export const emailChangeOtpBody = z.unknown().transform((body) => ({ otp: otp(fieldsOf(body).otp) }));
