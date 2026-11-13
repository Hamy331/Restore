import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { AuditQuery } from '../admin.dto.js';
import * as auditService from '../services/audit.service.js';

export async function listLogs(_req: AuthRequest, res: Response) {
  ok(res, await auditService.listLogs(getInput<ValidatedInput<AuditQuery>>(res).query));
}
