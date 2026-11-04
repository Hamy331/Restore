import { Response } from 'express';
import { created, noContent, ok } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as homeService from './home.service.js';
import type { AreaQuery, BannerIdParams, BannerInput } from './home.dto.js';

export function getArea(_req: AuthRequest, res: Response) {
  ok(res, homeService.resolveArea(getInput<ValidatedInput<AreaQuery>>(res).query));
}

export async function getBanners(_req: AuthRequest, res: Response) {
  ok(res, await homeService.listVisibleBanners());
}

export async function adminListBanners(_req: AuthRequest, res: Response) {
  ok(res, await homeService.listAllBanners());
}

export async function adminCreateBanner(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, BannerInput>>(res);
  created(res, await homeService.createBanner(req.user!.userId, body));
}

export async function adminUpdateBanner(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, BannerIdParams, BannerInput>>(res);
  ok(res, await homeService.updateBanner(req.user!.userId, params.id, body));
}

export async function adminDeleteBanner(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, BannerIdParams>>(res);
  await homeService.deleteBanner(req.user!.userId, params.id);
  noContent(res);
}
