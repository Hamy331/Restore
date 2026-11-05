import { Router, Response, NextFunction } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { ok } from '../../../common/http/response.js';
import { AuthRequest, requirePermission, verifyToken } from '../../../middlewares/auth.middleware.js';
import * as profile from '../services/profile.service.js';
import * as usersService from '../services/users.service.js';

/** /api/v1/users */
const usersRouter = Router();

const handle = (action: (req: AuthRequest) => Promise<unknown>) =>
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try { ok(res, await action(req)); } catch (error) { next(error); }
  };

/**
 * Hồ sơ người đang đăng nhập: UserProfileDto (trang chủ dùng để chào và hiện
 * avatar) cộng bio, số người theo dõi và trạng thái hoạt động (tab Tài khoản).
 */
usersRouter.get('/me', requirePermission(PERMISSION.PROFILE_READ), handle(async (req) => ({
  ...await usersService.getMyProfile(req.user!.userId),
  ...await profile.getProfile(req.user!.userId),
})));

usersRouter.use(verifyToken);
usersRouter.patch('/me', handle((req) => profile.updateProfile(req.user!.userId, req.body)));
usersRouter.post('/me/heartbeat', handle((req) => profile.heartbeat(req.user!.userId)));
usersRouter.get('/:id', handle((req) => profile.getProfile(req.params.id as string, req.user!.userId)));
usersRouter.get('/:id/followers', handle((req) =>
  profile.listFollows(req.params.id as string, req.user!.userId, 'followers', req.query.page)));
usersRouter.get('/:id/following', handle((req) =>
  profile.listFollows(req.params.id as string, req.user!.userId, 'following', req.query.page)));
usersRouter.post('/:id/follow', handle((req) => profile.follow(req.user!.userId, req.params.id as string)));
usersRouter.delete('/:id/follow', handle((req) => profile.unfollow(req.user!.userId, req.params.id as string)));

export default usersRouter;
