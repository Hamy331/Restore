import { z } from 'zod';
import type { Response } from 'express';
import type { AuthRequest } from '../../../../middlewares/auth.middleware.js';
import { parse } from '../../../../common/validation/schemas.js';
import { ok } from '../../../../common/http/response.js';
import { configuredProvider } from '../../assistant/services/gemini.provider.js';
import { indexDocument } from '../services/rag.service.js';
import { indexStatus } from '../repositories/rag.repository.js';
import { cleanupVectors } from '../services/cleanup.service.js';

export async function index(req: AuthRequest, res: Response) {
  const id = parse(z.string().min(1).max(100), req.params.id);
  parse(z.object({}).strict(), req.body ?? {});
  ok(res, await indexDocument(req.user!.userId, id, configuredProvider()));
}

export async function status(req: AuthRequest, res: Response) {
  ok(res, await indexStatus(parse(z.string().min(1).max(100), req.params.id)));
}

export async function cleanup(req: AuthRequest, res: Response) {
  parse(z.object({}).strict(), req.body ?? {});
  ok(res, await cleanupVectors());
}
