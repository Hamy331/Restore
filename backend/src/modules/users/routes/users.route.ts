import { listMyReviews, listReviews } from '../../chat/services/trade.service.js';
import { Router, Response, NextFunction } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { ok } from '../../../common/http/response.js';
import { AuthRequest, requirePermission, verifyToken } from '../../../middlewares/auth.middleware.js';
import * as profile from '../services/profile.service.js';
import * as usersService from '../services/users.service.js';
import { sellerAccess } from '../../shops/my-shop.service.js';
import * as savedAddresses from '../services/saved-address.service.js';
import * as recentAreas from '../services/recent-area.service.js';
import { emailChange } from '../services/email-change.service.js';
import { emailChangeBody, emailChangeOtpBody } from '../email-change.validator.js';
import { authRateLimits } from '../../../middlewares/rate-limit.middleware.js';
import { getInput, validate, type ValidatedInput } from '../../../middlewares/validate.middleware.js';

type EmailChangeInput = { email: string; password: string };

/** /api/v1/users */
const usersRouter = Router();

const handle = (action: (req: AuthRequest) => Promise<unknown>) =>
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try { ok(res, await action(req)); } catch (error) { next(error); }
  };

/**
 * Hồ sơ người đang đăng nhập: UserProfileDto (trang chủ dùng để chào và hiện
 * avatar) cộng bio, số người theo dõi và trạng thái hoạt động (tab Tài khoản),
 * shopStatus (PENDING | APPROVED | REJECTED | null = chưa lên cửa hàng), isPartner, canPost (được đăng bài lên Bảng tin).
 */
usersRouter.get('/me', requirePermission(PERMISSION.PROFILE_READ), handle(async (req) => ({
  ...await usersService.getMyProfile(req.user!.userId),
  ...await profile.getProfile(req.user!.userId),
  ...await sellerAccess(req.user!.userId),
})));

usersRouter.use(verifyToken);
/**
 * Sửa hồ sơ. Đổi username: 422 INVALID_USERNAME (sai luật), 409 USERNAME_TAKEN,
 * 422 USERNAME_CHANGE_TOO_SOON (chưa đủ 14 ngày từ lần đổi trước, details.nextChangeAt).
 */
usersRouter.patch('/me',handle((req) => profile.updateProfile(req.user!.userId, req.body)));
/**
 * Đổi email đăng nhập: gửi mã OTP tới email mới (body { email, password }),
 * rồi xác nhận mã (body { otp }). Rate limit chung với OTP đăng ký / quên mật khẩu.
 */
usersRouter.post('/me/email', validate({ body: emailChangeBody }), authRateLimits.sendOtp,
  (req: AuthRequest, res: Response, next: NextFunction) => {
    emailChange.request(req.user!.userId, getInput<ValidatedInput<undefined, undefined, EmailChangeInput>>(res).body)
      .then((data) => ok(res, data), next);
  });
usersRouter.post('/me/email/verify', validate({ body: emailChangeOtpBody }), authRateLimits.verifyOtp,
  (req: AuthRequest, res: Response, next: NextFunction) => {
    emailChange.verify(req.user!.userId, getInput<ValidatedInput<undefined, undefined, { otp: string }>>(res).body)
      .then((data) => ok(res, data), next);
  });
usersRouter.post('/me/heartbeat', handle((req) => profile.heartbeat(req.user!.userId)));
/** Sổ địa chỉ để chọn lại khi đăng tin: tối đa 5, mới dùng gần nhất trước */
usersRouter.get('/me/addresses', handle((req) => savedAddresses.listSavedAddresses(req.user!.userId)));
usersRouter.post('/me/addresses', handle((req) => savedAddresses.saveAddress(req.user!.userId, req.body)));
usersRouter.patch('/me/addresses/:addressId', handle((req) =>
  savedAddresses.renameAddress(req.user!.userId, req.params.addressId as string, req.body)));
usersRouter.delete('/me/addresses/:addressId', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try { await savedAddresses.deleteAddress(req.user!.userId, req.params.addressId as string); res.status(204).end(); } catch (error) { next(error); }
});
/**
 * Khu vực đã chọn gần đây ở trang chọn khu vực (tối đa 8, mới nhất trước), cùng dạng
 * kết quả GET /catalog/locations/search. POST { code } đưa lên đầu, DELETE /:code bỏ khỏi danh sách.
 */
usersRouter.get('/me/recent-areas', handle((req) => recentAreas.listRecentAreas(req.user!.userId)));
usersRouter.post('/me/recent-areas', handle((req) => recentAreas.saveRecentArea(req.user!.userId, req.body)));
usersRouter.delete('/me/recent-areas/:code', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try { await recentAreas.deleteRecentArea(req.user!.userId, req.params.code as string); res.status(204).end(); } catch (error) { next(error); }
});
usersRouter.get('/me/reviews', handle(req => listMyReviews(req.user!.userId, req.query)));
usersRouter.get('/:id', handle((req) => profile.getPublicProfile(req.params.id as string, req.user!.userId)));
usersRouter.get('/:id/reviews', handle(req => listReviews(req.params.id as string, req.query)));
usersRouter.get('/:id/followers', handle((req) =>
  profile.listFollows(req.params.id as string, req.user!.userId, 'followers', req.query.page)));
usersRouter.get('/:id/following', handle((req) =>
  profile.listFollows(req.params.id as string, req.user!.userId, 'following', req.query.page)));
usersRouter.post('/:id/follow', handle((req) => profile.follow(req.user!.userId, req.params.id as string)));
usersRouter.delete('/:id/follow', handle((req) => profile.unfollow(req.user!.userId, req.params.id as string)));

export default usersRouter;
