import { Response } from 'express';
import type { Pagination } from '../../../common/http/pagination.js';
import { noContent, ok, paginated } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import * as favoriteService from './favorite.service.js';

type IdInput = ValidatedInput<undefined, { id: string }>;

export async function listFavorites(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<Pagination>>(res);
  const { items, page } = await favoriteService.listFavorites(req.user!.userId, query);
  paginated(res, items, page);
}

export async function getFavorite(req: AuthRequest, res: Response) {
  const { params } = getInput<IdInput>(res);
  ok(res, await favoriteService.isFavorite(req.user!.userId, params.id));
}

export async function addFavorite(req: AuthRequest, res: Response) {
  const { params } = getInput<IdInput>(res);
  ok(res, await favoriteService.addFavorite(req.user!.userId, params.id));
}

export async function removeFavorite(req: AuthRequest, res: Response) {
  const { params } = getInput<IdInput>(res);
  await favoriteService.removeFavorite(req.user!.userId, params.id);
  noContent(res);
}
