import { NextFunction, Request, Response } from 'express';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import * as authService from './auth.service.js';
import {
  parseEmail,
  parseFullName,
  parseLoginPassword,
  parseOtp,
  parsePassword,
  parseToken,
  parseUsername,
} from './auth.validation.js';

export const getMe = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const user = await authService.getCurrentUser(req.user!.userId);
    return res.status(200).json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

export const login = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.loginUser(
      parseEmail(req.body?.email),
      parseLoginPassword(req.body?.password),
    );
    return res.status(200).json({ success: true, message: 'Đăng nhập thành công.', data: result });
  } catch (error) {
    next(error);
  }
};

export const register = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.registerUser({
      email: parseEmail(req.body?.email),
      password: parsePassword(req.body?.password),
      username: parseUsername(req.body?.username),
      fullName: parseFullName(req.body?.fullName),
    });
    return res.status(201).json({
      success: true,
      message: 'Đăng ký thành công. Vui lòng xác minh email.',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

export const resendRegistrationOtp = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.resendRegistrationOtp(parseEmail(req.body?.email));
    return res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const verifyRegistrationOtp = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.verifyRegistrationOtp(
      parseEmail(req.body?.email),
      parseOtp(req.body?.otp),
    );
    return res.status(200).json({ success: true, message: 'Email đã được xác minh.', data: result });
  } catch (error) {
    next(error);
  }
};

export const forgotPassword = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.forgotPassword(parseEmail(req.body?.email));
    return res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const verifyOtp = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.verifyPasswordResetOtp(
      parseEmail(req.body?.email),
      parseOtp(req.body?.otp),
    );
    return res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const resetPassword = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.resetPassword(
      parseToken(req.body?.resetToken, 'resetToken'),
      parsePassword(req.body?.newPassword, 'newPassword'),
    );
    return res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const refresh = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await authService.refreshSession(parseToken(req.body?.refreshToken, 'refreshToken'));
    return res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await authService.logout(parseToken(req.body?.refreshToken, 'refreshToken'));
    return res.status(200).json({ success: true, message: 'Đăng xuất thành công.' });
  } catch (error) {
    next(error);
  }
};
