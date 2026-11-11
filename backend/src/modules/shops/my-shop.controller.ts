import { Response } from 'express';
import { created, ok } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as myShopService from './my-shop.service.js';
import type { ShopCreateBody, ShopUpdateBody } from './my-shop.validator.js';

export async function get(req: AuthRequest, res: Response) {
  ok(res, await myShopService.getMyShop(req.user!.userId));
}

export async function create(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, ShopCreateBody>>(res);
  created(res, await myShopService.createMyShop(req.user!.userId, body));
}

export async function update(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, ShopUpdateBody>>(res);
  ok(res, await myShopService.updateMyShop(req.user!.userId, body));
}
