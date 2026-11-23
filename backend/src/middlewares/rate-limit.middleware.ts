import { NextFunction, Request, Response } from 'express';
import { AppError } from '../common/errors/app-error.js';

/**
 * Giới hạn số lần gọi API trong một khoảng thời gian (rate limit).
 *
 * Bộ đếm theo cửa sổ cố định, lưu trong bộ nhớ của tiến trình: đủ khi chạy một server.
 * Khi chạy nhiều server cùng lúc thì thay MemoryRateStore bằng bản lưu trên Redis (cùng các hàm).
 */
type Bucket = { count: number; resetAt: number };

export class MemoryRateStore {
  private readonly buckets = new Map<string, Bucket>();

  constructor(private readonly now: () => number = Date.now) {}

  /** Bộ đếm còn hiệu lực của [key], hết cửa sổ thì coi như chưa có */
  peek(key: string): Bucket | undefined {
    const bucket = this.buckets.get(key);
    return bucket && bucket.resetAt > this.now() ? bucket : undefined;
  }

  hit(key: string, windowMs: number) {
    const bucket = this.peek(key) ?? { count: 0, resetAt: this.now() + windowMs };
    bucket.count += 1;
    this.buckets.set(key, bucket);
  }

  /** Trả lại một lượt đã tính (VD lần đăng nhập thành công không tính vào số lần sai) */
  undo(key: string) {
    const bucket = this.peek(key);
    if (bucket && bucket.count > 0) bucket.count -= 1;
  }

  /** Bỏ các bộ đếm đã hết hạn cho nhẹ bộ nhớ */
  sweep() {
    const now = this.now();
    for (const [key, bucket] of this.buckets) if (bucket.resetAt <= now) this.buckets.delete(key);
  }

  millisUntilReset(key: string) {
    const bucket = this.peek(key);
    return bucket ? bucket.resetAt - this.now() : 0;
  }
}

export type RateRule = {
  /** Tên bộ đếm, để các luật dùng chung một khoá không cộng dồn vào nhau */
  name: string;
  limit: number;
  windowMs: number;
  /** Khoá đếm (IP, email...). undefined thì luật này bỏ qua request */
  key: (req: Request, res: Response) => string | undefined;
  /** Chỉ tính lần thất bại (mã >= 400), VD đăng nhập sai */
  onlyFailures?: boolean;
  /** Chỉ tính lần thành công (mã < 400), VD tạo tài khoản, gửi mã OTP */
  onlySuccesses?: boolean;
  /** Câu báo khi bị chặn, ghép thêm "Vui lòng thử lại sau …" */
  message: string;
};

const waitText = (ms: number) => {
  const seconds = Math.max(1, Math.ceil(ms / 1000));
  return seconds < 60 ? `${seconds} giây` : `${Math.ceil(seconds / 60)} phút`;
};

/** IP người gọi; sau proxy cần đặt TRUST_PROXY để Express đọc đúng IP thật */
export const clientIp = (req: Request) => req.ip ?? req.socket?.remoteAddress ?? 'unknown';

export function rateLimit(rules: RateRule[], store: MemoryRateStore) {
  return (req: Request, res: Response, next: NextFunction) => {
    const keyed = rules.flatMap((rule) => {
      const key = rule.key(req, res);
      return key === undefined ? [] : [{ rule, key: `${rule.name}:${key}` }];
    });

    const blocked = keyed.filter(({ rule, key }) => (store.peek(key)?.count ?? 0) >= rule.limit);
    if (blocked.length) {
      // Chặn bởi nhiều luật thì báo theo luật phải chờ lâu nhất
      const longest = blocked
        .map(({ rule, key }) => ({ rule, waitMs: store.millisUntilReset(key) }))
        .reduce((a, b) => (b.waitMs > a.waitMs ? b : a));
      res.setHeader('Retry-After', String(Math.max(1, Math.ceil(longest.waitMs / 1000))));
      return next(new AppError(429, 'RATE_LIMITED',
        `${longest.rule.message} Vui lòng thử lại sau ${waitText(longest.waitMs)}.`, undefined,
        { retryAfterSeconds: Math.max(1, Math.ceil(longest.waitMs / 1000)) }));
    }

    // Tính ngay khi nhận request để nhiều request gửi dồn cùng lúc vẫn bị đếm đủ,
    // rồi trả lại lượt không thuộc loại cần đếm khi đã biết kết quả
    for (const { rule, key } of keyed) store.hit(key, rule.windowMs);
    const conditional = keyed.filter(({ rule }) => rule.onlyFailures || rule.onlySuccesses);
    if (conditional.length) {
      res.once('finish', () => {
        const failed = res.statusCode >= 400;
        for (const { rule, key } of conditional) {
          if ((rule.onlyFailures && !failed) || (rule.onlySuccesses && failed)) store.undo(key);
        }
      });
    }
    next();
  };
}

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;

/** Email đã làm sạch bởi validate() (chữ thường, bỏ khoảng trắng) */
const inputEmail = (res: Response) => {
  const email = (res.locals.input?.body as { email?: unknown } | undefined)?.email;
  return typeof email === 'string' ? email : undefined;
};

/** Các mức giới hạn cho /auth. Đặt sau validate() để đọc được email đã làm sạch */
export function createAuthRateLimits(store = new MemoryRateStore()) {
  return {
    store,
    /** Dò mật khẩu: 5 lần sai / 15 phút cho mỗi cặp IP + email, 20 lần sai / 15 phút cho mỗi IP */
    login: rateLimit([
      {
        name: 'login-account', limit: 5, windowMs: 15 * MINUTE, onlyFailures: true,
        key: (req, res) => `${clientIp(req)}|${inputEmail(res) ?? ''}`,
        message: 'Bạn đã đăng nhập sai quá nhiều lần.',
      },
      {
        name: 'login-ip', limit: 20, windowMs: 15 * MINUTE, onlyFailures: true, key: clientIp,
        message: 'Thiết bị này đã đăng nhập sai quá nhiều lần.',
      },
    ], store),
    /** Tạo tài khoản rác: 5 tài khoản / giờ cho mỗi IP */
    register: rateLimit([{
      name: 'register-ip', limit: 5, windowMs: HOUR, onlySuccesses: true, key: clientIp,
      message: 'Bạn đã tạo quá nhiều tài khoản.',
    }], store),
    /** Gửi email OTP: 5 mã / giờ cho mỗi email, 10 yêu cầu / giờ cho mỗi IP (ngoài 60 giây chờ giữa hai lần gửi) */
    sendOtp: rateLimit([
      {
        name: 'otp-email', limit: 5, windowMs: HOUR, onlySuccesses: true, key: (_req, res) => inputEmail(res),
        message: 'Email này đã nhận quá nhiều mã xác minh.',
      },
      {
        name: 'otp-ip', limit: 10, windowMs: HOUR, key: clientIp,
        message: 'Bạn đã yêu cầu quá nhiều mã xác minh.',
      },
    ], store),
    /** Đoán mã OTP / mã đặt lại mật khẩu: 20 lần sai / 15 phút cho mỗi IP (ngoài 5 lần sai cho mỗi mã) */
    verifyOtp: rateLimit([{
      name: 'verify-ip', limit: 20, windowMs: 15 * MINUTE, onlyFailures: true, key: clientIp,
      message: 'Bạn đã nhập sai mã quá nhiều lần.',
    }], store),
    /** Làm mới token / đăng xuất: 120 lần / phút cho mỗi IP */
    token: rateLimit([{
      name: 'token-ip', limit: 120, windowMs: MINUTE, key: clientIp,
      message: 'Có quá nhiều yêu cầu từ thiết bị này.',
    }], store),
  };
}

export const authRateLimits = createAuthRateLimits();
setInterval(() => authRateLimits.store.sweep(), 5 * MINUTE).unref();
