import { Response } from 'express';
import { created, noContent, ok, paginated } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import type { AlertIdParams, DraftInput, MatchesQuery, PreviewQuery } from './wanted-alert.dto.js';
import * as wantedAlertService from './wanted-alert.service.js';

export async function listAlerts(req: AuthRequest, res: Response) {
  ok(res, await wantedAlertService.listAlerts(req.user!.userId));
}

export async function getAlert(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, AlertIdParams>>(res);
  ok(res, await wantedAlertService.getAlert(req.user!.userId, params));
}

export async function createAlert(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, DraftInput>>(res);
  created(res, await wantedAlertService.createAlert(req.user!.userId, body));
}

export async function preview(req: AuthRequest, res: Response) {
  const { query, body } = getInput<ValidatedInput<PreviewQuery, undefined, DraftInput>>(res);
  ok(res, await wantedAlertService.preview(req.user!.userId, body, query));
}

export async function deleteAlert(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, AlertIdParams>>(res);
  await wantedAlertService.deleteAlert(req.user!.userId, params);
  noContent(res);
}

export async function markSeen(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, AlertIdParams>>(res);
  await wantedAlertService.markSeen(req.user!.userId, params);
  noContent(res);
}

export async function listMatches(req: AuthRequest, res: Response) {
  const { params, query } = getInput<ValidatedInput<MatchesQuery, AlertIdParams>>(res);
  const { items, page } = await wantedAlertService.listMatches(req.user!.userId, params, query);
  paginated(res, items, page);
}
