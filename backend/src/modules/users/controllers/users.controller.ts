import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import * as usersService from '../services/users.service.js';

export async function getMe(req: AuthRequest, res: Response) {
  ok(res, await usersService.getMyProfile(req.user!.userId));
}
