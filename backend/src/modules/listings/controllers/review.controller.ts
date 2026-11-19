import { Response } from 'express';
import { created, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { ListingIdParams } from '../listing.dto.js';
import type { z } from 'zod';
import { userReviewBody } from '../review.validator.js';
import * as reviewService from '../services/review.service.js';

type ReviewInput = z.output<typeof userReviewBody>;

export async function create(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ListingIdParams, ReviewInput>>(res);
  created(res, await reviewService.createUserReview(req.user!.userId, params.id, body));
}

export async function list(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  ok(res, await reviewService.listListingReviews(params.id));
}
