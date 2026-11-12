import { Response } from 'express';
import { paginated } from '../../common/http/response.js';
import { pageQuery, parse } from '../../common/validation/schemas.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import * as followingService from './following.service.js';

const page = (req: AuthRequest) => parse(pageQuery({ defaultLimit: 20, maxLimit: 50 }), req.query);

export async function shops(req: AuthRequest, res: Response) {
  const { items, page: info } = await followingService.listFollowedShops(req.user!.userId, page(req));
  paginated(res, items, info);
}

export async function listings(req: AuthRequest, res: Response) {
  const { items, page: info } = await followingService.listFollowedListings(req.user!.userId, page(req));
  paginated(res, items, info);
}

export async function myFollowers(req: AuthRequest, res: Response) {
  const { items, page: info } = await followingService.listMyShopFollowers(req.user!.userId, page(req));
  paginated(res, items, info);
}
