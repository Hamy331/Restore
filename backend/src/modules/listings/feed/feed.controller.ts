import { Response } from 'express';
import { ok, paginated } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import * as feedService from './feed.service.js';
import type { FeedQuery, RecommendedQuery } from './feed.validation.js';

export async function listFeed(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<FeedQuery>>(res);
  const { items, page } = await feedService.listFeed(req.user?.userId, query);
  paginated(res, items, page);
}

export async function listRecommended(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<RecommendedQuery>>(res);
  ok(res, await feedService.listRecommended(req.user?.userId, query));
}
