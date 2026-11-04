import type { z } from 'zod';
import type { emailBody, loginBody, otpBody, refreshTokenBody, registerBody, resetPasswordBody } from './auth.validator.js';

/* Vào (suy ra từ schema). Kết quả trả ra do auth.service quyết định, giữ nguyên như API cũ. */

export type LoginInput = z.output<typeof loginBody>;
export type RegisterInput = z.output<typeof registerBody>;
export type EmailInput = z.output<typeof emailBody>;
export type OtpInput = z.output<typeof otpBody>;
export type ResetPasswordInput = z.output<typeof resetPasswordBody>;
export type RefreshTokenInput = z.output<typeof refreshTokenBody>;
