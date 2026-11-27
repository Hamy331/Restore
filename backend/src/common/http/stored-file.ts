import type { Response } from 'express';
import type { StoredFile } from '../../services/storage.service.js';

/**
 * Trả file đã lưu: có URL CDN thì chuyển hướng 302 (VPS không gửi byte ảnh), không thì gửi byte.
 * [cacheControl] áp cho cả hai: tên file là UUID, nội dung không đổi nên cache lâu được.
 */
export function sendStored(res: Response, file: StoredFile, cacheControl: string) {
  res.setHeader('Cache-Control', cacheControl);
  if ('url' in file) {
    res.redirect(302, file.url);
    return;
  }
  res.type(file.contentType).send(file.bytes);
}
