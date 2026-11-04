import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import * as mediaService from '../services/media.service.js';

export async function upload(req: AuthRequest, res: Response) {
  ok(res, await mediaService.upload(req.headers['content-type']?.split(';')[0], req.body));
}

export async function read(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, { filename: string }>>(res);
  const { bytes, extension } = await mediaService.read(req.user, params.filename);
  res.setHeader('Cache-Control', 'private, no-store');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.type(extension).send(bytes);
}
