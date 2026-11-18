import { Prisma } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { ListQuery, NotificationIdParams, toNotificationDto } from './notification.dto.js';
import { schedulePushDispatch } from './notification.push.js';
import * as notificationRepository from './notification.repository.js';
import { MAX_NOTIFICATIONS_PER_USER, NotificationType, typesOfGroup } from './notification.type.js';

/** Một thông báo cần gửi (xem notify) */
export type NotificationInput = {
  userId: string;
  type: NotificationType;
  /** Câu tiếng Việt dự phòng; app tự dựng câu theo type + data khi biết loại này */
  title: string;
  body: string;
  data?: Record<string, string | number | boolean | null>;
  imageUrl?: string | null;
  /** Route trong app khi bấm, VD /listings/<id> */
  link?: string | null;
  /** Chống gửi trùng: người nhận đã có thông báo cùng khoá thì bỏ qua (VD nhắc hết hạn của một lần hết hạn) */
  dedupeKey?: string;
};

/* ---------- API của người dùng ---------- */

export async function list(userId: string, { page, limit, skip, group, unread }: ListQuery) {
  const where: Prisma.NotificationWhereInput = {
    userId,
    ...(group && { type: { in: typesOfGroup(group) } }),
    ...(unread && { readAt: null }),
  };
  const [items, totalItems] = await notificationRepository.findPage(where, limit, skip);
  return { items: items.map(toNotificationDto), page: { page, limit, totalItems } };
}

export const unreadCount = async (userId: string) => ({ count: await notificationRepository.countUnread(userId) });

export async function markRead(userId: string, { id }: NotificationIdParams) {
  const { count } = await notificationRepository.markRead(userId, id, new Date());
  if (!count && !(await notificationRepository.exists(userId, id))) throw notFound();
}

export async function markAllRead(userId: string) {
  const { count } = await notificationRepository.markAllRead(userId, new Date());
  return { updated: count };
}

export async function remove(userId: string, { id }: NotificationIdParams) {
  const { count } = await notificationRepository.remove(userId, id);
  if (!count) throw notFound();
}

const notFound = () => new AppError(404, 'NOTIFICATION_NOT_FOUND', 'Không tìm thấy thông báo.');

/* ---------- Module khác gọi ---------- */

const clip = (value: string, max: number) => (value.length > max ? `${value.slice(0, max - 1)}…` : value);

/**
 * Ghi thông báo cho người dùng. Truyền [tx] để ghi cùng transaction với nghiệp vụ
 * (VD duyệt tin): nghiệp vụ lỗi thì thông báo cũng không có.
 * Mỗi người giữ tối đa MAX_NOTIFICATIONS_PER_USER thông báo mới nhất.
 * Sau khi ghi, push FCM được hẹn gửi khi transaction đã commit (xem notification.push.ts).
 */
export async function notify(inputs: NotificationInput | NotificationInput[], tx?: Prisma.TransactionClient) {
  const list = Array.isArray(inputs) ? inputs : [inputs];
  if (!list.length) return;
  const db = tx ?? prisma;
  const { count } = await notificationRepository.createMany(db, list.map((input) => ({
    userId: input.userId,
    type: input.type,
    title: clip(input.title, 160),
    body: clip(input.body, 500),
    data: (input.data ?? {}) as Prisma.InputJsonValue,
    imageUrl: input.imageUrl ?? null,
    link: input.link ? input.link.slice(0, 300) : null,
    dedupeKey: input.dedupeKey ? input.dedupeKey.slice(0, 160) : null,
  })));
  // Toàn bộ là bản trùng (đã gửi trước đó) thì không có gì mới
  if (!count) return;
  await notificationRepository.trim(db, [...new Set(list.map((input) => input.userId))], MAX_NOTIFICATIONS_PER_USER);
  schedulePushDispatch();
}
