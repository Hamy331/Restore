import { Response } from 'express';
import { created, ok } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as posterService from './poster.service.js';
import type { AdminPosterQuery, PosterCreateBody, PosterRejectBody, PosterUpdateBody } from './poster.validator.js';
import type { ShopIdParams } from './shop.validator.js';

const posterId = (res: Response) => getInput<ValidatedInput<undefined, ShopIdParams>>(res).params.id;

export async function mine(req: AuthRequest, res: Response) {
  ok(res, await posterService.getMyPosters(req.user!.userId));
}

export async function create(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, PosterCreateBody>>(res);
  created(res, await posterService.createPoster(req.user!.userId, body));
}

export async function update(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ShopIdParams, PosterUpdateBody>>(res);
  ok(res, await posterService.updatePoster(req.user!.userId, params.id, body));
}

export async function stop(req: AuthRequest, res: Response) {
  ok(res, await posterService.stopPoster(req.user!.userId, posterId(res)));
}

export async function adminList(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<AdminPosterQuery>>(res);
  ok(res, await posterService.adminListPosters(query));
}

export async function approve(req: AuthRequest, res: Response) {
  ok(res, await posterService.approvePoster(req.user!.userId, posterId(res)));
}

export async function reject(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ShopIdParams, PosterRejectBody>>(res);
  ok(res, await posterService.rejectPoster(req.user!.userId, params.id, body));
}
