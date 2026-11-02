import { Response } from 'express';
import { created, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { ListingIdParams } from '../listing.dto.js';
import * as imageService from '../services/image.service.js';

export async function add(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  const contentType = req.headers['content-type']?.split(';')[0];
  created(res, await imageService.addImage(req.user!.userId, params.id, contentType, req.body));
}

export async function reorder(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, ListingIdParams>>(res);
  ok(res, await imageService.reorderImages(req.user!.userId, params.id, req.body));
}

export async function read(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, { filename: string }>>(res);
  const { bytes, contentType } = await imageService.readImage(req.user, params.filename);
  res.setHeader('Cache-Control', 'private, no-store');
  res.type(contentType);
  res.send(bytes);
}
