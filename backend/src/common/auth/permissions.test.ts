import assert from 'node:assert/strict';
import test from 'node:test';
import { Role } from '@prisma/client';
import type { NextFunction, Response } from 'express';
import { AuthRequest, authorizePermission, requirePermission } from '../../middlewares/auth.middleware.js';
import { hasPermission, PERMISSION, Permission, ROLE_PERMISSIONS } from './permissions.js';

/**
 * Quyền → vai trò được phép, đúng như các route đang chặn bằng authorizeRoles hôm nay.
 * Đổi bảng ROLE_PERMISSIONS mà không sửa bảng này thì test đỏ, tránh mở quyền nhầm.
 */
const EXPECTED: Record<Permission, Role[]> = {
  [PERMISSION.PROFILE_READ]: [Role.USER, Role.ADMIN],
  [PERMISSION.LISTING_MANAGE_OWN]: [Role.USER],
  [PERMISSION.FAVORITE_READ]: [Role.USER],
  [PERMISSION.FAVORITE_WRITE]: [Role.USER],
  [PERMISSION.STORE_PURCHASE]: [Role.USER],
  [PERMISSION.PROMOTION_PURCHASE]: [Role.USER],
  [PERMISSION.REPORT_SUBMIT]: [Role.USER],
  [PERMISSION.SUPPORT_TICKET]: [Role.USER],
  [PERMISSION.ADMIN_ACCESS]: [Role.ADMIN],
  [PERMISSION.USER_MANAGE]: [Role.ADMIN],
  [PERMISSION.CATALOG_MANAGE]: [Role.ADMIN],
  [PERMISSION.BANNER_MANAGE]: [Role.ADMIN],
  [PERMISSION.LISTING_MODERATE]: [Role.ADMIN],
  [PERMISSION.STORE_ORDER_MANAGE]: [Role.ADMIN],
  [PERMISSION.PROMOTION_MANAGE]: [Role.ADMIN],
  [PERMISSION.CONTENT_MANAGE]: [Role.ADMIN],
};

/** Chạy middleware với req/res giả, trả về status + body, hoặc 'next' nếu cho qua */
async function run(middleware: (req: AuthRequest, res: Response, next: NextFunction) => unknown, req: Partial<AuthRequest>) {
  return new Promise<{ status: number; body: unknown } | 'next'>((resolve) => {
    let status = 200;
    const res = {
      status(code: number) { status = code; return this; },
      json(body: unknown) { resolve({ status, body }); return this; },
    } as unknown as Response;
    void middleware({ headers: {}, ...req } as AuthRequest, res, () => resolve('next'));
  });
}

const user = (role: Role) => ({ userId: `user-${role}`, email: `${role}@restore.test`, role });

test('every permission is granted to exactly the roles the routes allow today', () => {
  for (const [permission, roles] of Object.entries(EXPECTED) as [Permission, Role[]][]) {
    for (const role of Object.values(Role)) {
      assert.equal(hasPermission(role, permission), roles.includes(role), `${role} → ${permission}`);
    }
  }
  const all = Object.values(ROLE_PERMISSIONS).flat();
  assert.deepEqual(new Set(all), new Set(Object.values(PERMISSION)), 'mọi quyền đều được gán cho ít nhất một vai trò');
  assert.equal(hasPermission(undefined, PERMISSION.PROFILE_READ), false);
});

test('authorizePermission: 401 without user, 403 for a missing permission, next otherwise', async () => {
  for (const [permission, roles] of Object.entries(EXPECTED) as [Permission, Role[]][]) {
    const middleware = authorizePermission(permission);
    assert.deepEqual(await run(middleware, {}), {
      status: 401, body: { success: false, error: 'Vui lòng đăng nhập để tiếp tục.', code: 'AUTH_REQUIRED' },
    });
    for (const role of Object.values(Role)) {
      const result = await run(middleware, { user: user(role) });
      if (roles.includes(role)) assert.equal(result, 'next', `${role} → ${permission}`);
      else assert.deepEqual(result, {
        status: 403, body: { success: false, error: 'Bạn không có quyền thực hiện thao tác này.', code: 'FORBIDDEN' },
      }, `${role} → ${permission}`);
    }
  }
});

test('authorizePermission with several permissions requires all of them', async () => {
  const both = authorizePermission(PERMISSION.PROFILE_READ, PERMISSION.BANNER_MANAGE);
  assert.equal(await run(both, { user: user(Role.ADMIN) }), 'next');
  assert.equal((await run(both, { user: user(Role.USER) }) as { status: number }).status, 403);
});

test('requirePermission verifies the bearer token first', async () => {
  const middleware = requirePermission(PERMISSION.FAVORITE_WRITE);
  assert.deepEqual(await run(middleware, {}), {
    status: 401, body: { success: false, error: 'Vui lòng đăng nhập để tiếp tục.', code: 'AUTH_REQUIRED' },
  });
  assert.deepEqual(await run(middleware, { headers: { authorization: 'Bearer not-a-jwt' } }), {
    status: 401, body: { success: false, error: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.', code: 'INVALID_ACCESS_TOKEN' },
  });
});
