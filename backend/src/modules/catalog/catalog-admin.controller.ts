import { Response } from 'express';
import { ok } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as catalogAdminService from './catalog-admin.service.js';
import type { ConditionInput, ConditionParams, CreateCategoryInput, UpdateCategoryInput } from './catalog.validator.js';

export async function getCatalog(_req: AuthRequest, res: Response) {
  ok(res, await catalogAdminService.getCatalog());
}

export async function createCategory(req: AuthRequest, res: Response) {
  ok(res, await catalogAdminService.createCategory(req.user!.userId, getInput<ValidatedInput<undefined, undefined, CreateCategoryInput>>(res).body));
}

export async function updateCategory(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, { id: string }, UpdateCategoryInput>>(res);
  ok(res, await catalogAdminService.updateCategory(req.user!.userId, params.id, body));
}

export async function updateCondition(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, ConditionParams, ConditionInput>>(res);
  ok(res, await catalogAdminService.updateCondition(req.user!.userId, params, body));
}
