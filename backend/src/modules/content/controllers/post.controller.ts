import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { AdminPostListQuery, PageQuery, PostInput } from '../content.dto.js';
import * as postService from '../services/post.service.js';

export async function list(_req: AuthRequest, res: Response) {
  ok(res, await postService.listPublished(getInput<ValidatedInput<PageQuery>>(res).query));
}

export async function getBySlug(_req: AuthRequest, res: Response) {
  ok(res, await postService.getPublished(getInput<ValidatedInput<undefined, { slug: string }>>(res).params.slug));
}

/* ---------- /admin/posts ---------- */

export async function listForAdmin(_req: AuthRequest, res: Response) {
  ok(res, await postService.listForAdmin(getInput<ValidatedInput<AdminPostListQuery>>(res).query));
}

export async function create(req: AuthRequest, res: Response) {
  ok(res, await postService.save(req.user!.userId, undefined, getInput<ValidatedInput<undefined, undefined, PostInput>>(res).body));
}

export async function update(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, { id: string }, PostInput>>(res);
  ok(res, await postService.save(req.user!.userId, params.id, body));
}
