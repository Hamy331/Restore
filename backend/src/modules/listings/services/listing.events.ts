import type { NextFunction, Request, Response } from 'express';

/** Kết nối SSE của người đang mở trang chi tiết, theo mã tin (một tiến trình backend) */
const viewers = new Map<string, Set<Response>>();

/** GET /listings/:id/events: giữ kết nối, gửi `event: changed` khi tin vừa được sửa / bán / ẩn / duyệt */
export function watchListing(req: Request, res: Response) {
  const id = String(req.params.id);
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();
  res.write(': connected\n\n');
  const group = viewers.get(id) ?? new Set<Response>();
  group.add(res);
  viewers.set(id, group);
  const keepAlive = setInterval(() => res.write(': keep-alive\n\n'), 25000);
  res.on('close', () => {
    clearInterval(keepAlive);
    group.delete(res);
    if (!group.size) viewers.delete(id);
  });
}

export function publishListingChanged(listingId: string) {
  for (const res of viewers.get(listingId) ?? []) res.write('event: changed\ndata: {}\n\n');
}

/** Đặt trước controller của route có `:id`: request thành công thì báo người đang xem tin đó tải lại */
export function notifyViewers(req: Request, res: Response, next: NextFunction) {
  const id = String(req.params.id);
  res.on('finish', () => {
    if (res.statusCode < 300) publishListingChanged(id);
  });
  next();
}
