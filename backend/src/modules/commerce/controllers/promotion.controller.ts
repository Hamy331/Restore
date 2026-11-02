import { Response } from 'express';
import { created, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { IdParams, PromotionPackageInput, PurchaseInput } from '../commerce.dto.js';
import * as promotionService from '../services/promotion.service.js';

export async function listPackages(_req: AuthRequest, res: Response) {
  ok(res, await promotionService.listPackages());
}

export async function createPackage(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, PromotionPackageInput>>(res);
  created(res, await promotionService.createPackage(req.user!.userId, body));
}

export async function updatePackage(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, IdParams, PromotionPackageInput>>(res);
  ok(res, await promotionService.updatePackage(req.user!.userId, params.id, body));
}

export async function listMine(req: AuthRequest, res: Response) {
  ok(res, await promotionService.listMine(req.user!.userId));
}

export async function redeem(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, PurchaseInput>>(res);
  created(res, await promotionService.redeem(req.user!.userId, body));
}

export async function createOrder(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, PurchaseInput>>(res);
  created(res, await promotionService.createOrder(req.user!.userId, body));
}

export async function listPendingOrders(_req: AuthRequest, res: Response) {
  ok(res, await promotionService.listPendingOrders());
}

export async function confirmOrder(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, IdParams>>(res);
  ok(res, await promotionService.confirmOrder(req.user!.userId, params.id, req.body?.reason));
}

/** Trả { success: true } không kèm data, như API cũ */
export async function rejectOrder(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, IdParams>>(res);
  await promotionService.rejectPromotionOrder(req.user!.userId, params.id, req.body?.reason);
  res.json({ success: true });
}
