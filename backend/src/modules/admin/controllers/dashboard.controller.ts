import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import * as dashboardService from '../services/dashboard.service.js';

export async function getOverview(_req: AuthRequest, res: Response) {
  ok(res, await dashboardService.getOverview());
}
