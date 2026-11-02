import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { KnowledgeInput, KnowledgeSearchQuery, KnowledgeUploadBody, KnowledgeUploadQuery, PageQuery, VersionInput } from '../content.dto.js';
import * as knowledgeService from '../services/knowledge.service.js';

export async function search(_req: AuthRequest, res: Response) {
  ok(res, await knowledgeService.search(getInput<ValidatedInput<KnowledgeSearchQuery>>(res).query));
}

export async function upload(req: AuthRequest, res: Response) {
  const { query, body } = getInput<ValidatedInput<KnowledgeUploadQuery, undefined, KnowledgeUploadBody>>(res);
  ok(res, await knowledgeService.upload(req.user!.userId, query.title, body.content));
}

/* ---------- /admin/knowledge ---------- */

export async function listForAdmin(_req: AuthRequest, res: Response) {
  ok(res, await knowledgeService.listForAdmin(getInput<ValidatedInput<PageQuery>>(res).query));
}

export async function syncCatalog(req: AuthRequest, res: Response) {
  ok(res, await knowledgeService.syncCatalog(req.user!.userId));
}

export async function create(req: AuthRequest, res: Response) {
  ok(res, await knowledgeService.save(req.user!.userId, undefined, getInput<ValidatedInput<undefined, undefined, KnowledgeInput>>(res).body));
}

export async function update(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, { id: string }, KnowledgeInput>>(res);
  ok(res, await knowledgeService.save(req.user!.userId, params.id, body));
}

export async function index(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, { id: string }, VersionInput>>(res);
  ok(res, await knowledgeService.index(req.user!.userId, params.id, body.updatedAt));
}

export async function remove(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, { id: string }, VersionInput>>(res);
  ok(res, await knowledgeService.remove(req.user!.userId, params.id, body.updatedAt));
}
