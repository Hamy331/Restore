import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { KnowledgeSearchQuery, KnowledgeUploadBody, KnowledgeUploadQuery } from '../content.dto.js';
import * as knowledgeService from '../services/knowledge.service.js';

export async function search(_req: AuthRequest, res: Response) {
  ok(res, await knowledgeService.search(getInput<ValidatedInput<KnowledgeSearchQuery>>(res).query));
}

export async function upload(req: AuthRequest, res: Response) {
  const { query, body } = getInput<ValidatedInput<KnowledgeUploadQuery, undefined, KnowledgeUploadBody>>(res);
  ok(res, await knowledgeService.upload(req.user!.userId, query.title, body.content));
}
