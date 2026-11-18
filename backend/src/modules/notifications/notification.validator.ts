import { z } from 'zod';
import { idParam, oneOf, optionalBool, pageQuery, parse, str, strictBody } from '../../common/validation/schemas.js';
import { NOTIFICATION_GROUPS } from './notification.type.js';

/**
 * Query của GET /notifications: page, limit (mặc định 20, tối đa 50),
 * group? (listing | wallet | activity | system), unread? (true chỉ lấy chưa đọc)
 */
export const listQuery = z
  .object({ group: z.unknown().optional(), unread: z.unknown().optional() })
  .passthrough()
  .transform((query) => ({
    ...parse(pageQuery({ defaultLimit: 20, maxLimit: 50 }), query),
    group: query.group == null || query.group === '' ? null : parse(oneOf('group', NOTIFICATION_GROUPS), query.group),
    unread: parse(optionalBool('unread'), query.unread) ?? false,
  }));

export const notificationIdParams = idParam(64);

export const PUSH_PLATFORMS = ['android', 'ios', 'web'] as const;

/** Body POST /notifications/devices: { token, platform } */
export const registerDeviceBody = strictBody({ token: str('token', { max: 512 }), platform: oneOf('platform', PUSH_PLATFORMS) });
export type RegisterDeviceBody = z.output<typeof registerDeviceBody>;

/** Body DELETE /notifications/devices: { token } */
export const unregisterDeviceBody = strictBody({ token: str('token', { max: 512 }) });
export type UnregisterDeviceBody = z.output<typeof unregisterDeviceBody>;
