import { Response } from 'express';
import { created, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { AutoExtendInput, ExtendInput, FeatureInput, ListingIdParams, ListingInput, ListingShortIdParams, MineQuery, StatusInput } from '../listing.dto.js';
import { getInsights } from '../services/insights.service.js';
import * as listingService from '../services/listing.service.js';
import { rememberListingAddress } from '../../users/index.js';
import { assertNoContentFlags } from '../content-flags.js';

/** Body có payWithCredits: true khi người dùng đồng ý trả xu cho tin vượt hạn mức */
export const wantsToPay = (req: AuthRequest) => (req.body as { payWithCredits?: unknown } | undefined)?.payWithCredits === true;

/** Body có allowDuplicate: true khi người dùng vẫn muốn đăng mới dù đã có tin giống vậy đã ẩn / hết hạn */
export const allowsDuplicate = (req: AuthRequest) => (req.body as { allowDuplicate?: unknown } | undefined)?.allowDuplicate === true;

/** Body có acceptFlags: true khi người dùng đã thấy cảnh báo CONTENT_FLAGGED và vẫn muốn gửi duyệt */
export const acceptsFlags = (req: AuthRequest) => (req.body as { acceptFlags?: unknown } | undefined)?.acceptFlags === true;

export async function create(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, ListingInput>>(res);
  assertNoContentFlags(acceptsFlags(req), body.title, body.description);
  const listing = await listingService.createListing(req.user!.userId, body, wantsToPay(req), allowsDuplicate(req));
  // Đăng xong thì lưu địa chỉ vào sổ địa chỉ để lần sau chọn lại
  await rememberListingAddress(req.user!.userId, body.location);
  created(res, listing);
}

export async function update(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, ListingInput>>(res);
  assertNoContentFlags(acceptsFlags(req), body.title, body.description);
  const listing = await listingService.updateListing(req.user!.userId, params.id, body, wantsToPay(req));
  await rememberListingAddress(req.user!.userId, body.location);
  ok(res, listing);
}

/** Bỏ bản sửa đang chờ duyệt / bị từ chối của tin đã duyệt */
export async function discardEdit(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  ok(res, await listingService.discardRevision(req.user!.userId, params.id));
}

export async function changeStatus(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, StatusInput>>(res);
  ok(res, await listingService.changeStatus(req.user!.userId, params.id, body.status, body.payWithCredits));
}

export async function extend(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, ExtendInput>>(res);
  ok(res, await listingService.extendListing(req.user!.userId, params.id, body.days));
}

export async function autoExtend(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, AutoExtendInput>>(res);
  ok(res, await listingService.setAutoExtend(req.user!.userId, params.id, body.enabled));
}

export async function boost(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams, undefined>>(res);
  ok(res, await listingService.boostListing(req.user!.userId, params.id));
}

export async function insights(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<{ days: 7 | 30 }, undefined, undefined>>(res);
  ok(res, await getInsights(req.user!.userId, query.days));
}

export async function promotionHub(req: AuthRequest, res: Response) {
  ok(res, await listingService.getPromotionHub(req.user!.userId));
}

export async function promotion(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams, undefined>>(res);
  ok(res, await listingService.getPromotionOverview(req.user!.userId, params.id));
}

export async function featureQuote(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams, undefined>>(res);
  ok(res, await listingService.getFeatureQuote(req.user!.userId, params.id));
}

export async function feature(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, FeatureInput>>(res);
  ok(res, await listingService.featureListing(req.user!.userId, params.id, body.packageId));
}

export async function postingQuota(req: AuthRequest, res: Response) {
  ok(res, await listingService.getPostingQuota(req.user!.userId));
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

/** Đổi mã số ngắn trong URL thành mã tin (UUID) */
export async function resolveShortId(_req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingShortIdParams>>(res);
  ok(res, await listingService.resolveShortId(params.shortId));
}

export async function getById(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  ok(res, await listingService.viewListing(req.user, params.id));
}
