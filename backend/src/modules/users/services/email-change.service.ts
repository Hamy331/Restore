import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';
import bcrypt from 'bcrypt';
import { Prisma } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { getSecuritySecret } from '../../../config/env.js';
import { prisma } from '../../../lib/prisma.js';
import { sendEmailChangedNotice, sendOtpEmail } from '../../../services/email.service.js';

/**
 * Đổi email đăng nhập: gửi mã OTP tới email MỚI, nhập đúng mã mới đổi, xong
 * báo cho email cũ. Yêu cầu đang chờ giữ trong bộ nhớ (mỗi người một yêu cầu,
 * hết hạn sau 5 phút), giống bộ đếm rate limit: đủ khi chạy một server, khởi
 * động lại thì người dùng chỉ cần gửi mã lại.
 */
const OTP_TTL_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;

type Pending = {
  newEmail: string;
  /** Email lúc gửi mã: đổi xong / đổi chỗ khác thì mã cũ hết dùng được */
  currentEmail: string;
  hash: string;
  sentAt: number;
  expiresAt: number;
  attempts: number;
};

type Account = { id: string; email: string; password: string | null; status: string };

export type EmailChangeDeps = {
  findUser: (id: string) => Promise<Account | null>;
  findUserIdByEmail: (email: string) => Promise<string | null>;
  updateEmail: (id: string, email: string) => Promise<void>;
  sendOtp: (to: string, otp: string) => Promise<void>;
  sendNotice: (oldEmail: string, newEmail: string) => Promise<void>;
  secret: () => string;
  now: () => number;
};

const defaultDeps: EmailChangeDeps = {
  findUser: (id) => prisma.user.findUnique({
    where: { id }, select: { id: true, email: true, password: true, status: true },
  }),
  findUserIdByEmail: async (email) =>
    (await prisma.user.findUnique({ where: { email }, select: { id: true } }))?.id ?? null,
  updateEmail: async (id, email) => {
    await prisma.user.update({ where: { id }, data: { email } });
  },
  sendOtp: (to, otp) => sendOtpEmail(to, otp, 'change-email'),
  sendNotice: sendEmailChangedNotice,
  secret: () => getSecuritySecret('OTP_SECRET'),
  now: Date.now,
};

const emailTaken = () => new AppError(409, 'EMAIL_TAKEN', 'Email đã được sử dụng.', 'email');

export function createEmailChangeService(deps: EmailChangeDeps = defaultDeps) {
  const pending = new Map<string, Pending>();
  const hash = (userId: string, email: string, otp: string) =>
    createHmac('sha256', deps.secret()).update(`${userId}:EMAIL_CHANGE:${email}:${otp}`).digest('hex');

  const sweep = (now: number) => {
    for (const [id, item] of pending) if (item.expiresAt <= now) pending.delete(id);
  };

  async function activeUser(userId: string) {
    const user = await deps.findUser(userId);
    if (!user || user.status !== 'ACTIVE') {
      throw new AppError(401, 'ACCOUNT_UNAVAILABLE', 'Tài khoản không còn khả dụng.');
    }
    return user;
  }

  /** Gửi mã tới [email] mới sau khi kiểm tra lại mật khẩu hiện tại */
  async function request(userId: string, { email, password }: { email: string; password: string }) {
    const now = deps.now();
    sweep(now);
    const user = await activeUser(userId);
    if (email === user.email.toLowerCase()) {
      throw new AppError(422, 'SAME_EMAIL', 'Email mới trùng với email hiện tại.', 'email');
    }
    // Tài khoản đăng nhập bằng mật khẩu thì phải nhập lại, để người mượn máy
    // đang đăng nhập sẵn không đổi được email
    if (user.password && !(await bcrypt.compare(password, user.password))) {
      throw new AppError(400, 'WRONG_PASSWORD', 'Mật khẩu không đúng.', 'password');
    }
    const owner = await deps.findUserIdByEmail(email);
    if (owner && owner !== userId) throw emailTaken();
    const previous = pending.get(userId);
    const wait = previous ? RESEND_COOLDOWN_MS - (now - previous.sentAt) : 0;
    if (wait > 0) {
      throw new AppError(429, 'OTP_RATE_LIMITED',
        `Vui lòng chờ ${Math.ceil(wait / 1000)} giây trước khi yêu cầu mã mới.`);
    }
    const otp = randomInt(100000, 1000000).toString();
    await deps.sendOtp(email, otp);
    pending.set(userId, {
      newEmail: email, currentEmail: user.email, hash: hash(userId, email, otp),
      sentAt: now, expiresAt: now + OTP_TTL_MS, attempts: 0,
    });
    return {
      email,
      expiresInSeconds: OTP_TTL_MS / 1000,
      resendAfterSeconds: RESEND_COOLDOWN_MS / 1000,
    };
  }

  /** Nhập đúng [otp] thì đổi email và báo cho email cũ */
  async function verify(userId: string, { otp }: { otp: string }) {
    const now = deps.now();
    const item = pending.get(userId);
    if (!item) {
      throw new AppError(400, 'EMAIL_CHANGE_NOT_REQUESTED',
        'Bạn chưa yêu cầu đổi email hoặc yêu cầu đã hết hạn.');
    }
    if (item.expiresAt <= now) {
      pending.delete(userId);
      throw new AppError(410, 'OTP_EXPIRED', 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.');
    }
    if (item.attempts >= MAX_ATTEMPTS) {
      throw new AppError(429, 'OTP_ATTEMPTS_EXCEEDED', 'Bạn đã nhập sai quá nhiều lần. Vui lòng yêu cầu mã mới.');
    }
    const expected = Buffer.from(item.hash, 'hex');
    const candidate = Buffer.from(hash(userId, item.newEmail, otp), 'hex');
    if (expected.length !== candidate.length || !timingSafeEqual(expected, candidate)) {
      item.attempts += 1;
      throw new AppError(400, 'INVALID_OTP', 'Mã OTP không chính xác.', 'otp');
    }
    const user = await activeUser(userId);
    if (user.email !== item.currentEmail) {
      pending.delete(userId);
      throw new AppError(409, 'EMAIL_CHANGE_STALE', 'Email tài khoản đã thay đổi. Vui lòng yêu cầu mã mới.');
    }
    try {
      await deps.updateEmail(userId, item.newEmail);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') throw emailTaken();
      throw error;
    }
    pending.delete(userId);
    // Thư báo cho email cũ không được làm hỏng việc đổi email đã xong
    await deps.sendNotice(item.currentEmail, item.newEmail).catch((error: unknown) =>
      console.error('[email-change] notice to the old address failed', error));
    return { email: item.newEmail };
  }

  return { request, verify };
}

export const emailChange = createEmailChangeService();
