import { Request, Response } from 'express';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { EmailInput, LoginInput, OtpInput, RefreshTokenInput, RegisterInput, ResetPasswordInput } from '../auth.dto.js';
import * as authService from '../services/auth.service.js';
import { AppError } from '../../../common/errors/app-error.js';

/* Phản hồi giữ đúng như API cũ: một số API có thêm `message`, một số trải kết quả service ra ngoài `data`. */

const bodyOf = <B>(res: Response) => getInput<ValidatedInput<undefined, undefined, B>>(res).body;

/*
 * Web quản trị gửi header X-Session-Cookie: 1 để refresh token nằm trong cookie httpOnly
 * (JS trên trang không đọc được) thay vì body. App Flutter không gửi header nên giữ nguyên.
 * Cookie chỉ được đọc khi có header này: trang web khác không tự gắn header lạ được nếu không
 * qua CORS, nên cookie không bị dùng cho CSRF. Không đặt Max-Age: đóng trình duyệt là hết phiên.
 */
const REFRESH_COOKIE = 'restore_refresh';
const cookieOptions = {
  httpOnly: true,
  sameSite: 'strict',
  secure: process.env.NODE_ENV === 'production',
  path: '/api/v1/auth',
} as const;
const usesCookie = (req: Request) => req.get('X-Session-Cookie') === '1';

function refreshCookie(req: Request) {
  for (const part of req.headers.cookie?.split(';') ?? []) {
    const [name, ...value] = part.trim().split('=');
    if (name === REFRESH_COOKIE) return decodeURIComponent(value.join('='));
  }
}

/** Token từ body (Flutter) hoặc cookie (web quản trị). Thiếu token: Flutter nhận 422 như trước, web nhận 401. */
function refreshTokenOf(req: Request, res: Response) {
  const token = bodyOf<RefreshTokenInput>(res).refreshToken ?? (usesCookie(req) ? refreshCookie(req) : undefined);
  if (token) return token;
  throw usesCookie(req)
    ? new AppError(401, 'INVALID_REFRESH_TOKEN', 'Phiên đăng nhập đã hết hiệu lực.')
    : new AppError(422, 'TOKEN_REQUIRED', 'Phiên xác thực không hợp lệ.', 'refreshToken');
}

/** Web quản trị: chuyển refresh token vào cookie, không trả trong body */
function sessionData<T extends { refreshToken: string }>(req: Request, res: Response, data: T) {
  if (!usesCookie(req)) return data;
  res.cookie(REFRESH_COOKIE, data.refreshToken, cookieOptions);
  const { refreshToken: _moved, ...rest } = data;
  return rest;
}

export async function getMe(req: AuthRequest, res: Response) {
  res.status(200).json({ success: true, data: await authService.getCurrentUser(req.user!.userId) });
}

export async function login(req: Request, res: Response) {
  const { email, password } = bodyOf<LoginInput>(res);
  const data = sessionData(req, res, await authService.loginUser(email, password));
  res.status(200).json({ success: true, message: 'Đăng nhập thành công.', data });
}

export async function register(_req: Request, res: Response) {
  const data = await authService.registerUser(bodyOf<RegisterInput>(res));
  res.status(201).json({ success: true, message: 'Đăng ký thành công. Vui lòng xác minh email.', data });
}

export async function resendRegistrationOtp(_req: Request, res: Response) {
  res.status(200).json({ success: true, ...await authService.resendRegistrationOtp(bodyOf<EmailInput>(res).email) });
}

export async function verifyRegistrationOtp(_req: Request, res: Response) {
  const { email, otp } = bodyOf<OtpInput>(res);
  res.status(200).json({ success: true, message: 'Email đã được xác minh.', data: await authService.verifyRegistrationOtp(email, otp) });
}

export async function forgotPassword(_req: Request, res: Response) {
  res.status(200).json({ success: true, ...await authService.forgotPassword(bodyOf<EmailInput>(res).email) });
}

export async function verifyOtp(_req: Request, res: Response) {
  const { email, otp } = bodyOf<OtpInput>(res);
  res.status(200).json({ success: true, data: await authService.verifyPasswordResetOtp(email, otp) });
}

export async function resetPassword(_req: Request, res: Response) {
  const { resetToken, newPassword } = bodyOf<ResetPasswordInput>(res);
  res.status(200).json({ success: true, ...await authService.resetPassword(resetToken, newPassword) });
}

export async function refresh(req: Request, res: Response) {
  const token = refreshTokenOf(req, res);
  res.status(200).json({ success: true, data: sessionData(req, res, await authService.refreshSession(token)) });
}

export async function logout(req: Request, res: Response) {
  if (usesCookie(req)) {
    // Web: luôn xoá cookie; không còn cookie thì coi như đã đăng xuất
    const token = bodyOf<RefreshTokenInput>(res).refreshToken ?? refreshCookie(req);
    if (token) await authService.logout(token);
    res.clearCookie(REFRESH_COOKIE, cookieOptions);
  } else {
    await authService.logout(refreshTokenOf(req, res));
  }
  res.status(200).json({ success: true, message: 'Đăng xuất thành công.' });
}
