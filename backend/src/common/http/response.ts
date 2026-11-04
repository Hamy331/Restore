import { Response } from 'express';

/**
 * Định dạng phản hồi thống nhất cho mọi API.
 *
 * Thành công:   { success: true, data }
 * Phân trang:   { success: true, data: [...], pagination: {...}, meta: { page, limit, hasMore } }
 * Lỗi:          do error.middleware trả về { success: false, error, code, field? }
 */

export type PageInfo = { page: number; limit: number; totalItems: number };

export const ok = <T>(res: Response, data: T, status = 200) =>
  res.status(status).json({ success: true, data });

export const created = <T>(res: Response, data: T) => ok(res, data, 201);

export const noContent = (res: Response) => res.status(204).send();

export const paginated = <T>(res: Response, items: T[], { page, limit, totalItems }: PageInfo) => {
  const totalPages = Math.ceil(totalItems / limit);
  const hasMore = page < totalPages;
  return res.status(200).json({
    success: true,
    data: items,
    // pageSize giữ lại cho các màn hình cũ đang đọc pagination.pageSize
    pagination: { page, limit, pageSize: limit, totalItems, totalPages, hasMore },
    meta: { page, limit, hasMore },
  });
};
