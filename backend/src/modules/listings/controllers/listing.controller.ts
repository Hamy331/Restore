import { Response } from 'express';
import { created, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { ListingIdParams, ListingInput, MineQuery, StatusInput } from '../listing.dto.js';
import * as listingService from '../services/listing.service.js';

/** Body có payWithCredits: true khi người dùng đồng ý trả xu cho tin vượt hạn mức */
export const wantsToPay = (req: AuthRequest) => (req.body as { payWithCredits?: unknown } | undefined)?.payWithCredits === true;

export async function create(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, ListingInput>>(res);
  created(res, await listingService.createListing(req.user!.userId, body, wantsToPay(req)));
}

export async function update(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, ListingInput>>(res);
  ok(res, await listingService.updateListing(req.user!.userId, params.id, body, wantsToPay(req)));
}

export async function changeStatus(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, StatusInput>>(res);
  ok(res, await listingService.changeStatus(req.user!.userId, params.id, body.status));
}

export async function postingQuota(req: AuthRequest, res: Response) {
  ok(res, await listingService.getPostingQuota(req.user!.userId));
}

export async function summary(req: AuthRequest, res: Response) {
  ok(res, await listingService.getSummary(req.user!.userId));
}

/** Giữ dạng pagination cũ { page, pageSize, totalItems, totalPages } mà màn "Tin của tôi" đang đọc */
export async function listMine(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<MineQuery>>(res);
  const { items, pagination } = await listingService.listMine(req.user!.userId, query);
  res.json({ success: true, data: items, pagination });
}

export async function getMine(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  ok(res, await listingService.getMine(req.user!.userId, params.id));
}

export async function getById(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  ok(res, await listingService.viewListing(req.user, params.id));
}
