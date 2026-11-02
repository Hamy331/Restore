import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { PageQuery, ReportInput } from '../content.dto.js';
import * as reportService from '../services/report.service.js';

/** Trả 200 (không phải 201) như API cũ */
export async function create(req: AuthRequest, res: Response) {
  ok(res, await reportService.create(req.user!.userId, getInput<ValidatedInput<undefined, undefined, ReportInput>>(res).body));
}

export async function listMine(req: AuthRequest, res: Response) {
  ok(res, await reportService.listMine(req.user!.userId, getInput<ValidatedInput<PageQuery>>(res).query));
}
