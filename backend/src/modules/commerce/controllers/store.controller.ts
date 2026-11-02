import { Response } from 'express';
import { created, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { IdParams, StoreOrderInput } from '../commerce.dto.js';
import * as storeService from '../services/store.service.js';

export async function listCategories(_req: AuthRequest, res: Response) {
  ok(res, await storeService.listCategories());
}

export async function listPackages(_req: AuthRequest, res: Response) {
  ok(res, await storeService.listPackages());
}

export async function getMine(req: AuthRequest, res: Response) {
  ok(res, await storeService.getMyStore(req.user!.userId));
}

export async function createOrder(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, StoreOrderInput>>(res);
  created(res, await storeService.createOrder(req.user!.userId, body));
}

export async function listPendingOrders(_req: AuthRequest, res: Response) {
  ok(res, await storeService.listPendingOrders());
}

export async function confirmOrder(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, IdParams>>(res);
  ok(res, await storeService.confirmOrder(req.user!.userId, params.id, req.body?.reason));
}

/** Trả { success: true } không kèm data, như API cũ */
export async function rejectOrder(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, IdParams>>(res);
  await storeService.rejectStoreOrder(req.user!.userId, params.id, req.body?.reason);
  res.json({ success: true });
}
