import { Request, Response } from 'express';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import type { EmailInput, LoginInput, OtpInput, RefreshTokenInput, RegisterInput, ResetPasswordInput } from './auth.dto.js';
import * as authService from './auth.service.js';

/* Phản hồi giữ đúng như API cũ: một số API có thêm `message`, một số trải kết quả service ra ngoài `data`. */

const bodyOf = <B>(res: Response) => getInput<ValidatedInput<undefined, undefined, B>>(res).body;

export async function getMe(req: AuthRequest, res: Response) {
  res.status(200).json({ success: true, data: await authService.getCurrentUser(req.user!.userId) });
}

export async function login(_req: Request, res: Response) {
  const { email, password } = bodyOf<LoginInput>(res);
  res.status(200).json({ success: true, message: 'Đăng nhập thành công.', data: await authService.loginUser(email, password) });
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

export async function refresh(_req: Request, res: Response) {
  res.status(200).json({ success: true, data: await authService.refreshSession(bodyOf<RefreshTokenInput>(res).refreshToken) });
}

export async function logout(_req: Request, res: Response) {
  await authService.logout(bodyOf<RefreshTokenInput>(res).refreshToken);
  res.status(200).json({ success: true, message: 'Đăng xuất thành công.' });
}
