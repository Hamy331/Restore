import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { UserActionInput, UserIdParams, UserListQuery } from '../admin.dto.js';
import * as userService from '../services/user.service.js';

export async function getSelf(req: AuthRequest, res: Response) {
  ok(res, await userService.getSelf(req.user!.userId));
}

export async function listMembers(_req: AuthRequest, res: Response) {
  ok(res, await userService.listMembers(getInput<ValidatedInput<UserListQuery>>(res).query));
}

export async function act(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, UserIdParams, UserActionInput>>(res);
  ok(res, await userService.act(req.user!.userId, params.id, body));
}
