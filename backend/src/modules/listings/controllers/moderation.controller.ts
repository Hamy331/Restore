import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { DecisionInput, ListingIdParams } from '../listing.dto.js';
import * as moderationService from '../services/moderation.service.js';

/** Trả { success: true } không kèm data, như API cũ */
export async function decide(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, DecisionInput>>(res);
  await moderationService.decide(req.user!.userId, params.id, body);
  res.json({ success: true });
}

export async function listPending(_req: AuthRequest, res: Response) {
  ok(res, await moderationService.listPending());
}
