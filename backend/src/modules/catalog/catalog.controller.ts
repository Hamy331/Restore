import { Request, Response } from 'express';
import { ok } from '../../common/http/response.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as catalogService from './catalog.service.js';
import { Coordinates, LOCATION_COVERAGE } from './catalog.type.js';
import type { AddressSuggestQuery, AreaSearchQuery, ProvinceParams } from './catalog.validator.js';
import { suggestAddresses } from './address-suggest.service.js';

/** API địa chỉ trả thêm coverage ('full': toàn quốc) ngoài data, như API cũ */
const withCoverage = (res: Response, data: unknown) => res.json({ success: true, data, coverage: LOCATION_COVERAGE });

export async function listConditions(_req: Request, res: Response) {
  ok(res, await catalogService.listConditions());
}

export async function listCategories(_req: Request, res: Response) {
  ok(res, await catalogService.listCategories());
}

export function listProvinces(_req: Request, res: Response) {
  withCoverage(res, catalogService.listProvinces());
}

export function listWards(_req: Request, res: Response) {
  withCoverage(res, catalogService.listWards(getInput<ValidatedInput<undefined, ProvinceParams>>(res).params.code));
}

export function searchAreas(_req: Request, res: Response) {
  const { q, limit } = getInput<ValidatedInput<AreaSearchQuery>>(res).query;
  withCoverage(res, catalogService.searchAreas(q, limit));
}

export async function suggestAddress(_req: Request, res: Response) {
  ok(res, await suggestAddresses(getInput<ValidatedInput<AddressSuggestQuery>>(res).query));
}

export function reverseGeocode(_req: Request, res: Response) {
  withCoverage(res, catalogService.reverseGeocode(getInput<ValidatedInput<Coordinates>>(res).query));
}
