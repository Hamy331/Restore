import { Response } from 'express';
import { created, ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { ListingIdParams } from '../listing.dto.js';
import { thumbWidth } from '../../../services/image-thumbnail.service.js';
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
  const { bytes, contentType } = await imageService.readImage(req.user, params.filename, thumbWidth(req.query.w));
  // Tên file là UUID, nội dung không bao giờ đổi nên cache lâu được; private vì ảnh tin chưa duyệt
  // chỉ chủ tin xem được
  res.setHeader('Cache-Control', 'private, max-age=604800, immutable');
  res.type(contentType);
  res.send(bytes);
}
