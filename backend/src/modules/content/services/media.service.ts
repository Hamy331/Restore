import { randomUUID } from 'node:crypto';
import path from 'node:path';
import { hasPermission, PERMISSION } from '../../../common/auth/permissions.js';
import { AppError } from '../../../common/errors/app-error.js';
import type { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getObject, putObject } from '../../../services/storage.service.js';
import { imageExtension } from '../../listings/index.js';
import { MEDIA_NAME, MEDIA_PREFIX } from '../content.type.js';

/** Ảnh nội dung nằm ở khu 'admin' của storage (ổ đĩa hoặc Cloudinary, theo STORAGE_DRIVER) */
const AREA = 'admin';

/** Lưu ảnh bìa (JPEG, PNG, WebP tối đa 5 MB) */
export async function upload(contentType: string | undefined, bytes: unknown) {
  const extension = imageExtension(contentType, bytes);
  const filename = `${randomUUID()}.${extension}`;
  await putObject(AREA, filename, bytes as Buffer);
  return { url: `${MEDIA_PREFIX}${filename}` };
}

/** Đọc ảnh: chỉ người quản lý nội dung */
export async function read(viewer: AuthRequest['user'], filename: string) {
  const notFound = () => new AppError(404, 'IMAGE_NOT_FOUND', 'Không có ảnh.');
  if (!MEDIA_NAME.test(filename)) throw notFound();
  if (!hasPermission(viewer?.role, PERMISSION.CONTENT_MANAGE)) {
    throw notFound();
  }
  const bytes = await getObject(AREA, filename);
  if (!bytes) throw notFound();
  return { bytes, extension: path.extname(filename) };
}
