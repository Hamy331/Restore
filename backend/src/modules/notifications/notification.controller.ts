import { Response } from 'express';
import { noContent, ok, paginated } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import type { ListQuery, NotificationIdParams } from './notification.dto.js';
import * as notificationPush from './notification.push.js';
import * as notificationService from './notification.service.js';
import type { RegisterDeviceBody, UnregisterDeviceBody } from './notification.validator.js';

export async function list(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<ListQuery>>(res);
  const { items, page } = await notificationService.list(req.user!.userId, query);
  paginated(res, items, page);
}

export async function unreadCount(req: AuthRequest, res: Response) {
  ok(res, await notificationService.unreadCount(req.user!.userId));
}

export async function markRead(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, NotificationIdParams>>(res);
  await notificationService.markRead(req.user!.userId, params);
  noContent(res);
}

export async function markAllRead(req: AuthRequest, res: Response) {
  ok(res, await notificationService.markAllRead(req.user!.userId));
}

export async function remove(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, NotificationIdParams>>(res);
  await notificationService.remove(req.user!.userId, params);
  noContent(res);
}

export async function registerDevice(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, RegisterDeviceBody>>(res);
  await notificationPush.registerDevice(req.user!.userId, body.token, body.platform);
  noContent(res);
}

export async function unregisterDevice(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, UnregisterDeviceBody>>(res);
  await notificationPush.unregisterDevice(req.user!.userId, body.token);
  noContent(res);
}
