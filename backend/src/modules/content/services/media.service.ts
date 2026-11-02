import { randomUUID } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { hasPermission, PERMISSION } from '../../../common/auth/permissions.js';
import { AppError } from '../../../common/errors/app-error.js';
import type { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { imageExtension } from '../../listings/index.js';
import { MEDIA_NAME, MEDIA_PREFIX } from '../content.type.js';
import * as postRepository from '../repositories/post.repository.js';

// Ảnh nội dung đang lưu trên ổ đĩa; sẽ chuyển sang Supabase Storage (C24).
const folder = path.join(process.cwd(), 'uploads', 'admin');

/** Lưu ảnh bìa (JPEG, PNG, WebP tối đa 5 MB) */
export async function upload(contentType: string | undefined, bytes: unknown) {
  const extension = imageExtension(contentType, bytes);
  const filename = `${randomUUID()}.${extension}`;
  await mkdir(folder, { recursive: true });
  await writeFile(path.join(folder, filename), bytes as Buffer, { flag: 'wx' });
  return { url: `${MEDIA_PREFIX}${filename}` };
}

/** Đọc ảnh: ai cũng xem được ảnh bìa của bài đã đăng; ảnh khác chỉ người quản lý nội dung */
export async function read(viewer: AuthRequest['user'], filename: string) {
  const notFound = () => new AppError(404, 'IMAGE_NOT_FOUND', 'Không có ảnh.');
  if (!MEDIA_NAME.test(filename)) throw notFound();
  if (!hasPermission(viewer?.role, PERMISSION.CONTENT_MANAGE) && !await postRepository.isPublishedCover(`${MEDIA_PREFIX}${filename}`)) {
    throw notFound();
  }
  try {
    return { bytes: await readFile(path.join(folder, filename)), extension: path.extname(filename) };
  } catch (error) {
    throw (error as NodeJS.ErrnoException).code === 'ENOENT' ? notFound() : error;
  }
}
