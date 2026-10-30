import { Router, Response, NextFunction } from 'express';
import { AuthRequest, verifyToken } from '../../middlewares/auth.middleware.js';
import * as users from './users.service.js';

const router = Router();
router.use(verifyToken);
const handle = (action: (req: AuthRequest) => Promise<unknown>, status = 200) =>
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try { res.status(status).json({ success: true, data: await action(req) }); }
    catch (error) { next(error); }
  };

router.get('/me', handle((req) => users.getProfile(req.user!.userId)));
router.patch('/me', handle((req) => users.updateProfile(req.user!.userId, req.body)));
router.post('/me/heartbeat', handle((req) => users.heartbeat(req.user!.userId)));
router.get('/:id', handle((req) => users.getProfile(req.params.id as string)));
router.post('/:id/follow', handle((req) => users.follow(req.user!.userId, req.params.id as string)));
router.delete('/:id/follow', handle((req) => users.unfollow(req.user!.userId, req.params.id as string)));

export default router;
