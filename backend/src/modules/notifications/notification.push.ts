import { prisma } from '../../lib/prisma.js';
import { isPushEnabled, PushMessage, PushResult, sendPush } from '../../services/push.service.js';
import { groupOf } from './notification.type.js';

/**
 * Gửi push FCM cho thông báo vừa ghi (cả khi app đang mở: app nhận, hiện banner, cập nhật chuông).
 *
 * Thông báo có thể ghi trong transaction của nghiệp vụ, nên không gửi ngay lúc ghi: notify() hẹn
 * một lượt gửi sau PUSH_DELAY_MS, khi transaction đã commit. Lượt gửi lấy các dòng pushedAt = null
 * (ghi trong PUSH_WINDOW_MS gần nhất), đánh dấu pushedAt rồi gửi. Nghiệp vụ lỗi thì dòng không tồn tại,
 * không có push nhầm. Job quét lại mỗi 30 giây để không sót dòng commit chậm.
 */
const PUSH_DELAY_MS = 500;
/** Quá thời gian này mà chưa gửi (VD backend tắt) thì bỏ, không push thông báo cũ */
export const PUSH_WINDOW_MS = 15 * 60_000;
const BATCH = 200;

type Sender = (token: string, message: PushMessage) => Promise<PushResult>;
let sender: Sender = sendPush;
let enabled: () => boolean = isPushEnabled;

/** Test: thay hàm gửi thật */
export function setPushSenderForTest(fake: Sender | null) {
  sender = fake ?? sendPush;
  enabled = fake ? () => true : isPushEnabled;
}

let timer: NodeJS.Timeout | null = null;
let running: Promise<number> | null = null;

/** Hẹn một lượt gửi (gộp nhiều lần gọi liền nhau) */
export function schedulePushDispatch() {
  if (timer || !enabled()) return;
  timer = setTimeout(() => {
    timer = null;
    void dispatchPendingPushes().catch((error) => console.error('[push] dispatch failed', error));
  }, PUSH_DELAY_MS);
  timer.unref();
}

/** Gửi các thông báo chưa push; trả về số push đã gửi được. Chạy nối tiếp, không chồng lượt */
export async function dispatchPendingPushes(now = new Date()): Promise<number> {
  if (!enabled()) return 0;
  while (running) await running;
  running = dispatch(now).finally(() => { running = null; });
  return running;
}

async function dispatch(now: Date) {
  const rows = await prisma.notification.findMany({
    where: { pushedAt: null, createdAt: { gte: new Date(now.getTime() - PUSH_WINDOW_MS) } },
    orderBy: { createdAt: 'asc' },
    take: BATCH,
    select: { id: true, userId: true, type: true, title: true, body: true, data: true, imageUrl: true, link: true, createdAt: true },
  });
  if (!rows.length) return 0;
  const { count } = await prisma.notification.updateMany({
    where: { id: { in: rows.map((row) => row.id) }, pushedAt: null },
    data: { pushedAt: now },
  });
  if (!count) return 0;

  const userIds = [...new Set(rows.map((row) => row.userId))];
  const [devices, unread] = await Promise.all([
    prisma.pushDevice.findMany({ where: { userId: { in: userIds } }, select: { token: true, userId: true } }),
    prisma.notification.groupBy({ by: ['userId'], where: { userId: { in: userIds }, readAt: null }, _count: { _all: true } }),
  ]);
  const unreadOf = new Map(unread.map((row) => [row.userId, row._count._all]));
  const invalid = new Set<string>();
  let sent = 0;
  for (const row of rows) {
    const message: PushMessage = {
      title: row.title,
      body: row.body,
      imageUrl: row.imageUrl,
      data: {
        kind: 'notification',
        notificationId: row.id,
        type: row.type,
        group: groupOf(row.type),
        link: row.link ?? '',
        /** data của thông báo (JSON) để app dựng câu theo ngôn ngữ khi đang mở */
        payload: JSON.stringify(row.data ?? {}),
        createdAt: row.createdAt.toISOString(),
        unreadCount: String(unreadOf.get(row.userId) ?? 0),
        tag: row.id,
      },
    };
    for (const device of devices) {
      if (device.userId !== row.userId || invalid.has(device.token)) continue;
      const result = await sender(device.token, message);
      if (result === 'ok') sent++;
      if (result === 'invalid') invalid.add(device.token);
    }
  }
  if (invalid.size) await prisma.pushDevice.deleteMany({ where: { token: { in: [...invalid] } } });
  return sent;
}

/**
 * Push thẳng, không ghi Notification (tin nhắn chat 3.2: chat có số chưa đọc riêng).
 * [messages] theo người nhận; trả về số push đã gửi được.
 */
export async function pushToUsers(messages: { userId: string; message: PushMessage }[]): Promise<number> {
  if (!enabled() || !messages.length) return 0;
  const devices = await prisma.pushDevice.findMany({
    where: { userId: { in: [...new Set(messages.map((item) => item.userId))] } }, select: { token: true, userId: true },
  });
  const invalid = new Set<string>();
  let sent = 0;
  for (const { userId, message } of messages) {
    for (const device of devices) {
      if (device.userId !== userId || invalid.has(device.token)) continue;
      const result = await sender(device.token, message);
      if (result === 'ok') sent++;
      if (result === 'invalid') invalid.add(device.token);
    }
  }
  if (invalid.size) await prisma.pushDevice.deleteMany({ where: { token: { in: [...invalid] } } });
  return sent;
}

/* ---------- Thiết bị ---------- */

/** Lưu token FCM của thiết bị cho người dùng (token đã thuộc người khác thì chuyển sang người này) */
export const registerDevice = (userId: string, token: string, platform: string) =>
  prisma.pushDevice.upsert({
    where: { token },
    create: { userId, token, platform },
    update: { userId, platform },
    select: { id: true },
  });

/** Gỡ token (đăng xuất / tắt thông báo trên máy này) */
export const unregisterDevice = (userId: string, token: string) =>
  prisma.pushDevice.deleteMany({ where: { userId, token } });
