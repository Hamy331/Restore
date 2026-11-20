import { Prisma } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { ListQuery, NotificationIdParams, toNotificationDto } from './notification.dto.js';
import { schedulePushDispatch } from './notification.push.js';
import * as notificationRepository from './notification.repository.js';
import { IN_APP_ONLY_TYPES, MAX_NOTIFICATIONS_PER_USER, NotificationType, typesOfGroup } from './notification.type.js';

export type NotificationData = Record<string, string | number | boolean | null>;

/** Một thông báo cần gửi (xem notify) */
export type NotificationInput = {
  userId: string;
  type: NotificationType;
  /** Câu tiếng Việt dự phòng; app tự dựng câu theo type + data khi biết loại này */
  title: string;
  body: string;
  data?: NotificationData;
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
  const now = new Date();
  const { count } = await notificationRepository.createMany(db, list.map((input) => ({
    userId: input.userId,
    type: input.type,
    title: clip(input.title, 160),
    body: clip(input.body, 500),
    data: (input.data ?? {}) as Prisma.InputJsonValue,
    imageUrl: input.imageUrl ?? null,
    link: input.link ? input.link.slice(0, 300) : null,
    dedupeKey: input.dedupeKey ? input.dedupeKey.slice(0, 160) : null,
    // Loại chỉ hiện trong app: coi như đã push
    pushedAt: IN_APP_ONLY_TYPES.has(input.type) ? now : null,
  })));
  // Toàn bộ là bản trùng (đã gửi trước đó) thì không có gì mới
  if (!count) return;
  await notificationRepository.trim(db, [...new Set(list.map((input) => input.userId))], MAX_NOTIFICATIONS_PER_USER);
  schedulePushDispatch();
}

/** Thông báo gộp nhiều người (VD "Lan và 2 người khác đã lưu tin"), xem notifyGrouped */
export type GroupedInput = Omit<NotificationInput, 'dedupeKey' | 'body'> & {
  /** Khoá nhóm, VD fav:<listingId>; mỗi người nhận có tối đa một thông báo chưa đọc cho một khoá */
  groupKey: string;
  /** Người vừa làm hành động: đã có trong nhóm thì không tính thêm */
  actorId: string;
  /** Câu tiếng Việt dự phòng theo số người trong nhóm */
  body: (count: number) => string;
};

/** Số người tối đa nhớ trong một nhóm (để không tính trùng); nhóm lớn hơn vẫn đếm tiếp */
const MAX_GROUP_ACTORS = 50;

/**
 * Gộp hành động lặp lại vào một thông báo: người nhận còn thông báo chưa đọc cùng [groupKey] thì cập nhật nó
 * (count + 1, người mới nhất, đưa lên đầu), đã đọc thì bắt đầu nhóm mới. Không đi qua transaction của nghiệp vụ.
 */
export async function notifyGrouped(input: GroupedInput) {
  const { groupKey, actorId, body, ...rest } = input;
  const key = groupKey.slice(0, 160);
  const existing = await prisma.notification.findFirst({
    where: { userId: rest.userId, dedupeKey: key }, select: { id: true, readAt: true, data: true },
  });
  if (existing && !existing.readAt) {
    const data = (existing.data ?? {}) as NotificationData;
    const actors = String(data.actorIds ?? '').split(',').filter(Boolean);
    if (actors.includes(actorId)) return;
    const count = (Number(data.count) || actors.length || 1) + 1;
    await prisma.notification.update({
      where: { id: existing.id },
      data: {
        title: clip(rest.title, 160),
        body: clip(body(count), 500),
        data: { ...rest.data, count, actorIds: [actorId, ...actors].slice(0, MAX_GROUP_ACTORS).join(',') },
        imageUrl: rest.imageUrl ?? null,
        link: rest.link ? rest.link.slice(0, 300) : null,
        createdAt: new Date(),
      },
    });
    return;
  }
  // Nhóm cũ đã đọc: người này đã có trong nhóm thì thôi, không thì nhả khoá cho nhóm mới
  if (existing) {
    const actors = String(((existing.data ?? {}) as NotificationData).actorIds ?? '').split(',');
    if (actors.includes(actorId)) return;
    await prisma.notification.update({ where: { id: existing.id }, data: { dedupeKey: null } });
  }
  await notify({ ...rest, body: body(1), data: { ...rest.data, count: 1, actorIds: actorId }, dedupeKey: key });
}
