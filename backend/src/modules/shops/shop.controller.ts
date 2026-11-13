import { Response } from 'express';
import { noContent, ok, paginated } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as shopService from './shop.service.js';
import type { ShopIdParams, ShopListingsQuery } from './shop.validator.js';

const shopId = (res: Response) => getInput<ValidatedInput<undefined, ShopIdParams>>(res).params.id;

export async function overview(req: AuthRequest, res: Response) {
  ok(res, await shopService.overview(req.user?.userId));
}

export async function getShop(req: AuthRequest, res: Response) {
  ok(res, await shopService.getShop(req.user?.userId, shopId(res)));
}

export async function getBanners(req: AuthRequest, res: Response) {
  ok(res, await shopService.getBanners(req.user?.userId, shopId(res)));
}

export async function listListings(req: AuthRequest, res: Response) {
  const { query, params } = getInput<ValidatedInput<ShopListingsQuery, ShopIdParams>>(res);
  const { items, page } = await shopService.listShopListings(req.user?.userId, params.id, query);
  paginated(res, items, page);
}

export async function follow(req: AuthRequest, res: Response) {
  await shopService.setFollowing(req.user!.userId, shopId(res), true);
  noContent(res);
}

export async function unfollow(req: AuthRequest, res: Response) {
  await shopService.setFollowing(req.user!.userId, shopId(res), false);
  noContent(res);
}
