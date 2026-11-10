import { Response } from 'express';
import { created, noContent, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { DraftInput, ListingIdParams } from '../listing.dto.js';
import { allowsDuplicate, wantsToPay } from './listing.controller.js';
import * as draftService from '../services/draft.service.js';

export async function create(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, DraftInput>>(res);
  created(res, await draftService.createDraft(req.user!.userId, body));
}

export async function update(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, DraftInput>>(res);
  ok(res, await draftService.updateDraft(req.user!.userId, params.id, body));
}

export async function publish(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  ok(res, await draftService.publishDraft(req.user!.userId, params.id, wantsToPay(req), allowsDuplicate(req)));
}

export async function remove(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  await draftService.deleteDraft(req.user!.userId, params.id);
  noContent(res);
}

export async function quota(req: AuthRequest, res: Response) {
  ok(res, await draftService.getDraftQuota(req.user!.userId));
}
