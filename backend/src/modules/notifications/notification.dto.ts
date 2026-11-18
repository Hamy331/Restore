import { Prisma } from '@prisma/client';
import type { z } from 'zod';
import { groupOf } from './notification.type.js';
import type { listQuery, notificationIdParams } from './notification.validator.js';

/* ---------- Vào ---------- */

export type ListQuery = z.output<typeof listQuery>;
export type NotificationIdParams = z.output<typeof notificationIdParams>;

/* ---------- Ra ---------- */

export const notificationSelect = {
  id: true, type: true, title: true, body: true, data: true, imageUrl: true, link: true, readAt: true, createdAt: true,
} as const satisfies Prisma.NotificationSelect;

export type NotificationRecord = Prisma.NotificationGetPayload<{ select: typeof notificationSelect }>;

/**
 * Thông báo cho app (NotificationModel.fromJson):
 * { id, type, group, title, body, data {}, imageUrl, link, isRead, readAt, createdAt }
 */
export const toNotificationDto = (item: NotificationRecord) => ({
  id: item.id,
  type: item.type,
  group: groupOf(item.type),
  title: item.title,
  body: item.body,
  data: item.data && typeof item.data === 'object' && !Array.isArray(item.data) ? item.data : {},
  imageUrl: item.imageUrl,
  link: item.link,
  isRead: item.readAt != null,
  readAt: item.readAt,
  createdAt: item.createdAt,
});

export type NotificationDto = ReturnType<typeof toNotificationDto>;
