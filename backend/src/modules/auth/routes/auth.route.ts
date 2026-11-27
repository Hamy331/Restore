import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { authRateLimits as limit } from '../../../middlewares/rate-limit.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as authController from '../controllers/auth.controller.js';
import { emailBody, loginBody, otpBody, refreshTokenBody, registerBody, resetPasswordBody } from '../auth.validator.js';

/**
 * /api/v1/auth. Lỗi đầu vào trả 422 kèm mã theo trường:
 * INVALID_EMAIL, WEAK_PASSWORD, PASSWORD_REQUIRED, INVALID_USERNAME, INVALID_FULL_NAME, INVALID_OTP_FORMAT, TOKEN_REQUIRED.
 * Gọi quá nhiều lần (đăng nhập sai, gửi / nhập mã OTP, tạo tài khoản) trả 429 RATE_LIMITED kèm header
 * Retry-After (giây), xem các mức trong middlewares/rate-limit.middleware.ts.
 */
const authRouter = Router();

/**
 * Hồ sơ người đang đăng nhập (USER hoặc ADMIN)
 */
authRouter.get('/me', requirePermission(PERMISSION.PROFILE_READ), authController.getMe);

/**
 * Đăng nhập
 *
 * Body:
 *  - email: string
 *  - password: string
 *
 * Trả về: { message, data: { accessToken, refreshToken, user } }
 */
authRouter.post('/login', validate({ body: loginBody }), limit.login, authController.login);

/**
 * Đăng ký, gửi OTP xác minh email
 *
 * Body:
 *  - email: string
 *  - password: string (8-72, có chữ hoa, chữ thường, chữ số)
 *  - username: string (3-30, a-z 0-9 . _, có chữ cái, dấu chấm không ở đầu/cuối/liền nhau)
 *  - fullName: string (2-80)
 *
 * Trả về: 201 { message, data }
 */
authRouter.post('/register', validate({ body: registerBody }), limit.register, authController.register);

/**
 * Xác minh email bằng OTP đăng ký
 *
 * Body:
 *  - email: string
 *  - otp: string (6 chữ số)
 */
authRouter.post('/verify-registration-otp', validate({ body: otpBody }), limit.verifyOtp, authController.verifyRegistrationOtp);

/**
 * Gửi lại OTP đăng ký
 *
 * Body:
 *  - email: string
 */
authRouter.post('/resend-registration-otp', validate({ body: emailBody }), limit.sendOtp, authController.resendRegistrationOtp);

/**
 * Quên mật khẩu: gửi OTP đặt lại (trả cùng một thông báo dù email có tồn tại hay không)
 *
 * Body:
 *  - email: string
 */
authRouter.post('/forgot-password', validate({ body: emailBody }), limit.sendOtp, authController.forgotPassword);

/**
 * Xác minh OTP đặt lại mật khẩu
 *
 * Body:
 *  - email: string
 *  - otp: string (6 chữ số)
 *
 * Trả về: { data: { resetToken } }
 */
authRouter.post('/verify-otp', validate({ body: otpBody }), limit.verifyOtp, authController.verifyOtp);

/**
 * Đặt mật khẩu mới, thu hồi mọi phiên
 *
 * Body:
 *  - resetToken: string
 *  - newPassword: string (8-72, có chữ hoa, chữ thường, chữ số)
 */
authRouter.post('/reset-password', validate({ body: resetPasswordBody }), limit.verifyOtp, authController.resetPassword);

/**
 * Đổi refresh token lấy cặp token mới (refresh token cũ hết hiệu lực)
 *
 * Body:
 *  - refreshToken: string
 */
authRouter.post('/refresh', validate({ body: refreshTokenBody }), limit.token, authController.refresh);

/**
 * Đăng xuất: thu hồi refresh token
 *
 * Body:
 *  - refreshToken: string
 */
authRouter.post('/logout', validate({ body: refreshTokenBody }), limit.token, authController.logout);

export default authRouter;
