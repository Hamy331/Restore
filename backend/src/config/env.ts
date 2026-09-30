import { AppError } from '../errors/app-error.js';

export const getRequiredEnv = (name: string): string => {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
};

export const getSecuritySecret = (name: string): string => {
  const value = process.env[name]?.trim();
  if (value) return value;
  if (process.env.NODE_ENV !== 'production') return getRequiredEnv('JWT_SECRET');
  throw new Error(`Missing required environment variable: ${name}`);
};

const assertStrongSecret = (name: string) => {
  if (getRequiredEnv(name).length < 32) {
    throw new Error(`${name} must contain at least 32 characters.`);
  }
};

export const validateEnvironment = () => {
  getRequiredEnv('DATABASE_URL');
  getRequiredEnv('RESEND_API_KEY');
  const from = getRequiredEnv('EMAIL_FROM');
  if (process.env.NODE_ENV === 'production') {
    assertStrongSecret('JWT_SECRET');
    assertStrongSecret('JWT_REFRESH_SECRET');
    assertStrongSecret('JWT_RESET_SECRET');
    assertStrongSecret('OTP_SECRET');
  } else {
    getRequiredEnv('JWT_SECRET');
  }

  if (process.env.NODE_ENV === 'production' && from.endsWith('@resend.dev')) {
    throw new Error(
      'EMAIL_FROM must use a verified Resend domain in production; onboarding@resend.dev only supports Resend test recipients.',
    );
  }
};

export const ensureVerifiedEmailSender = (recipient: string) => {
  const from = getRequiredEnv('EMAIL_FROM');
  if (from.endsWith('@resend.dev')) {
    const testRecipient = process.env.RESEND_TEST_RECIPIENT?.trim().toLowerCase();
    if (!testRecipient || testRecipient !== recipient.toLowerCase()) {
      throw new AppError(
        503,
        'EMAIL_PROVIDER_RESTRICTED',
        'Dịch vụ email đang ở chế độ thử nghiệm. Quản trị viên cần xác minh domain Resend và cấu hình EMAIL_FROM trước khi gửi cho người dùng.',
      );
    }
  }
  return from;
};
