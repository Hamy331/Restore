import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';
import bcrypt from 'bcrypt';
import { OtpPurpose, User } from '@prisma/client';
import { getSecuritySecret } from '../../config/env.js';
import { AppError } from '../../errors/app-error.js';
import { sendOtpEmail } from '../../services/email.service.js';
import * as repository from './auth.repository.js';
import * as tokens from './token.service.js';

const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_OTP_ATTEMPTS = 5;
const DUMMY_PASSWORD_HASH = '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.';

type RegistrationData = {
  email: string;
  password: string;
  username: string;
  fullName: string;
};

const publicUser = (user: User) => ({
  id: user.id,
  email: user.email,
  fullName: user.fullName,
  username: user.username,
  phone: user.phone,
  avatarUrl: user.avatarUrl,
  role: user.role,
  status: user.status,
  ratingAverage: user.ratingAverage,
  ratingCount: user.ratingCount,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const makeOtp = () => randomInt(100000, 1000000).toString();
const hashOtp = (userId: string, purpose: OtpPurpose, otp: string) =>
  createHmac('sha256', getSecuritySecret('OTP_SECRET'))
    .update(`${userId}:${purpose}:${otp}`)
    .digest('hex');

const otpMatches = (expectedHash: string, candidateHash: string) => {
  const expected = Buffer.from(expectedHash, 'hex');
  const candidate = Buffer.from(candidateHash, 'hex');
  return expected.length === candidate.length && timingSafeEqual(expected, candidate);
};

const assertCanSendOtp = (lastSentAt: Date | null) => {
  if (!lastSentAt) return;
  const retryAfter = OTP_RESEND_COOLDOWN_MS - (Date.now() - lastSentAt.getTime());
  if (retryAfter > 0) {
    throw new AppError(
      429,
      'OTP_RATE_LIMITED',
      `Vui lòng chờ ${Math.ceil(retryAfter / 1000)} giây trước khi yêu cầu mã mới.`,
    );
  }
};

const validateOtpForUser = async (user: User, otp: string, purpose: OtpPurpose) => {
  if (user.otpPurpose !== purpose || !user.otpCode || !user.otpExpires) {
    throw new AppError(400, 'INVALID_OTP', 'Mã OTP không hợp lệ.');
  }
  if (user.otpExpires <= new Date()) {
    throw new AppError(410, 'OTP_EXPIRED', 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.');
  }
  if (user.otpAttempts >= MAX_OTP_ATTEMPTS) {
    throw new AppError(429, 'OTP_ATTEMPTS_EXCEEDED', 'Bạn đã nhập sai quá nhiều lần. Vui lòng yêu cầu mã mới.');
  }
  const candidate = hashOtp(user.id, purpose, otp);
  if (!otpMatches(user.otpCode, candidate)) {
    await repository.incrementOtpAttempts(user.id);
    throw new AppError(400, 'INVALID_OTP', 'Mã OTP không chính xác.');
  }
};

const setAndSendOtp = async (user: User, purpose: OtpPurpose) => {
  assertCanSendOtp(user.otpLastSentAt);
  const otp = makeOtp();
  await repository.setOtp(user.id, {
    otpCode: hashOtp(user.id, purpose, otp),
    otpExpires: new Date(Date.now() + OTP_TTL_MS),
    otpPurpose: purpose,
  });
  await sendOtpEmail(user.email, otp, purpose === 'REGISTER' ? 'register' : 'forgot-password');
  await repository.markOtpSent(user.id);
};

export const loginUser = async (email: string, password: string) => {
  const user = await repository.findUserByEmail(email);
  const matches = await bcrypt.compare(password, user?.password ?? DUMMY_PASSWORD_HASH);
  if (!user || !matches) {
    throw new AppError(401, 'INVALID_CREDENTIALS', 'Email hoặc mật khẩu không chính xác.');
  }
  if (user.status === 'UNVERIFIED') {
    throw new AppError(403, 'EMAIL_NOT_VERIFIED', 'Vui lòng xác minh email trước khi đăng nhập.');
  }
  if (user.status !== 'ACTIVE') {
    throw new AppError(403, 'ACCOUNT_DISABLED', 'Tài khoản đã bị tạm ngưng hoặc vô hiệu hóa.');
  }
  return { user: publicUser(user), ...(await tokens.issueAuthTokens(user)) };
};

export const registerUser = async (data: RegistrationData) => {
  const [emailUser, usernameUser] = await Promise.all([
    repository.findUserByEmail(data.email),
    repository.findUserByUsername(data.username),
  ]);
  if (usernameUser && usernameUser.id !== emailUser?.id) {
    throw new AppError(409, 'USERNAME_TAKEN', 'Tên người dùng đã được sử dụng.', 'username');
  }
  if (emailUser && emailUser.status !== 'UNVERIFIED') {
    throw new AppError(409, 'EMAIL_TAKEN', 'Email đã được sử dụng.', 'email');
  }
  if (emailUser) assertCanSendOtp(emailUser.otpLastSentAt);

  const password = await bcrypt.hash(data.password, 12);
  const otp = makeOtp();
  const otpExpires = new Date(Date.now() + OTP_TTL_MS);
  const user = emailUser
    ? await repository.updateUnverifiedUser(emailUser.id, {
        username: data.username,
        fullName: data.fullName,
        password,
        otpCode: hashOtp(emailUser.id, 'REGISTER', otp),
        otpExpires,
      })
    : await repository.createUnverifiedUser({
        ...data,
        password,
        otpCode: '',
        otpExpires,
      });

  if (!emailUser) {
    await repository.setOtp(user.id, {
      otpCode: hashOtp(user.id, 'REGISTER', otp),
      otpExpires,
      otpPurpose: 'REGISTER',
    });
  }
  await sendOtpEmail(user.email, otp, 'register');
  await repository.markOtpSent(user.id);
  return { email: user.email, expiresIn: OTP_TTL_MS / 1000 };
};

export const resendRegistrationOtp = async (email: string) => {
  const user = await repository.findUserByEmail(email);
  if (!user) throw new AppError(404, 'ACCOUNT_NOT_FOUND', 'Không tìm thấy tài khoản.');
  if (user.status !== 'UNVERIFIED') {
    throw new AppError(409, 'ALREADY_VERIFIED', 'Tài khoản đã được xác minh.');
  }
  await setAndSendOtp(user, 'REGISTER');
  return { message: 'Mã OTP mới đã được gửi.', expiresIn: OTP_TTL_MS / 1000 };
};

export const verifyRegistrationOtp = async (email: string, otp: string) => {
  const user = await repository.findUserByEmail(email);
  if (!user) throw new AppError(400, 'INVALID_OTP', 'Mã OTP không hợp lệ.');
  if (user.status !== 'UNVERIFIED') {
    throw new AppError(409, 'ALREADY_VERIFIED', 'Tài khoản đã được xác minh.');
  }
  await validateOtpForUser(user, otp, 'REGISTER');
  const updatedUser = await repository.activateUserAndClearOtp(user.id);
  return { user: publicUser(updatedUser), ...(await tokens.issueAuthTokens(updatedUser)) };
};

export const forgotPassword = async (email: string) => {
  const user = await repository.findUserByEmail(email);
  if (user?.status === 'ACTIVE') await setAndSendOtp(user, 'PASSWORD_RESET');
  return {
    message: 'Nếu email tồn tại và đang hoạt động, mã OTP đã được gửi.',
    expiresIn: OTP_TTL_MS / 1000,
  };
};

export const verifyPasswordResetOtp = async (email: string, otp: string) => {
  const user = await repository.findUserByEmail(email);
  if (!user || user.status !== 'ACTIVE') {
    throw new AppError(400, 'INVALID_OTP', 'Mã OTP không hợp lệ.');
  }
  await validateOtpForUser(user, otp, 'PASSWORD_RESET');
  return { resetToken: tokens.issuePasswordResetToken(user) };
};

export const resetPassword = async (resetToken: string, newPassword: string) => {
  const payload = tokens.verifyPasswordResetToken(resetToken);
  const user = await repository.findUserByEmail(payload.email);
  if (
    !user ||
    user.id !== payload.userId ||
    user.otpPurpose !== 'PASSWORD_RESET' ||
    !user.otpExpires ||
    user.otpExpires <= new Date()
  ) {
    throw new AppError(401, 'INVALID_RESET_SESSION', 'Phiên đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.');
  }
  const password = await bcrypt.hash(newPassword, 12);
  await repository.updatePasswordAndRevokeSessions(user.id, password);
  return { message: 'Đổi mật khẩu thành công.' };
};

export const refreshSession = tokens.rotateRefreshToken;
export const logout = tokens.revokeRefreshToken;

export const getCurrentUser = async (userId: string) => {
  const user = await repository.findPublicUserById(userId);
  if (!user || user.status !== 'ACTIVE') {
    throw new AppError(401, 'ACCOUNT_UNAVAILABLE', 'Tài khoản không còn khả dụng.');
  }
  return user;
};
