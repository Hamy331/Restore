import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Session } from './session';

const admin = { fullName: 'Quản trị', email: 'admin@restore.test', permissions: ['admin:access'] };
const ok = (data: unknown) => new Response(JSON.stringify({ success: true, data }), { status: 200 });
const fail = (status: number, code?: string) =>
  new Response(JSON.stringify({ success: false, error: 'Lỗi ' + status, code }), { status });

// Máy chủ giả giống backend: refresh token nằm trong cookie, mỗi lần refresh đổi token mới
let cookie: string | undefined;
let access: Set<string>;
let generation: number;
let me: () => Response;
let storage: Map<string, string>;
const savedAccess = () => storage.get('restore-admin-access');
type Fetch = (url: string, init: RequestInit) => Promise<Response>;
let fetchMock: ReturnType<typeof vi.fn<Fetch>>;
const calls = () => fetchMock.mock.calls.map(([url]) => url.replace('/api/v1', ''));
function issue() {
  generation++;
  cookie = 'r' + generation;
  access.add('a' + generation);
  return ok({ accessToken: 'a' + generation });
}

beforeEach(() => {
  cookie = undefined;
  access = new Set();
  generation = 0;
  me = () => ok(admin);
  storage = new Map();
  vi.stubGlobal('sessionStorage', {
    getItem: (k: string) => storage.get(k) ?? null,
    setItem: (k: string, v: string) => storage.set(k, v),
    removeItem: (k: string) => storage.delete(k),
  });
  fetchMock = vi.fn<Fetch>(async (url, init) => {
    const headers = new Headers(init.headers);
    const token = headers.get('Authorization')?.replace('Bearer ', '');
    const usesCookie = headers.get('X-Session-Cookie') === '1' && init.credentials === 'include';
    switch (url.replace('/api/v1', '')) {
      case '/auth/login':
        return issue();
      case '/auth/refresh':
        return usesCookie && cookie ? issue() : fail(401, 'INVALID_REFRESH_TOKEN');
      case '/auth/logout':
        cookie = undefined;
        return ok(null);
      case '/admin/me':
        return token && access.has(token) ? me() : fail(401);
      default:
        return token && access.has(token) ? ok(url) : fail(401);
    }
  });
  vi.stubGlobal('fetch', fetchMock);
});

describe('Session', () => {
  it('đăng nhập không đưa refresh token cho JS, chỉ gửi kèm cookie', async () => {
    const { admin: me } = await Session.login('admin@restore.test', 'x', vi.fn());
    expect(me).toEqual(admin);
    const [, init] = fetchMock.mock.calls[0];
    expect(init.credentials).toBe('include');
    expect(new Headers(init.headers).get('X-Session-Cookie')).toBe('1');
    expect(cookie).toBe('r1');
  });

  it('đăng nhập lưu access token (không lưu refresh token), đăng xuất thì xoá', async () => {
    const { session } = await Session.login('admin@restore.test', 'x', vi.fn());
    expect(savedAccess()).toBe('a1');
    expect([...storage.values()].join()).not.toContain('r1');
    await session.logout();
    expect(savedAccess()).toBeUndefined();
  });

  it('tải lại trang khi access token còn hạn thì không cần refresh', async () => {
    cookie = 'r0';
    access.add('a0');
    storage.set('restore-admin-access', 'a0');
    expect((await Session.restore(vi.fn()))?.admin).toEqual(admin);
    expect(calls()).toEqual(['/admin/me']);
  });

  it('access token đã lưu hết hạn thì refresh bằng cookie và lưu token mới', async () => {
    cookie = 'r0';
    storage.set('restore-admin-access', 'cu');
    expect((await Session.restore(vi.fn()))?.admin).toEqual(admin);
    expect(calls()).toEqual(['/admin/me', '/auth/refresh', '/admin/me']);
    expect(savedAccess()).toBe('a1');
  });

  it('access token đã lưu hết hạn và cookie cũng hết thì về form đăng nhập, không báo hết hạn', async () => {
    storage.set('restore-admin-access', 'cu');
    const expired = vi.fn();
    expect(await Session.restore(expired)).toBeUndefined();
    expect(expired).not.toHaveBeenCalled();
    expect(savedAccess()).toBeUndefined();
  });

  it('tài khoản không có quyền admin thì đăng xuất ngay', async () => {
    me = () => ok({ ...admin, permissions: [] });
    await expect(Session.login('user@restore.test', 'x', vi.fn())).rejects.toThrow('quyền quản trị');
    expect(cookie).toBeUndefined();
  });

  it('chưa đăng nhập thì mở lại phiên trả undefined, không báo lỗi', async () => {
    expect(await Session.restore(vi.fn())).toBeUndefined();
  });

  it('tải lại trang thì dùng cookie để mở lại phiên', async () => {
    cookie = 'r0';
    const restored = await Session.restore(vi.fn());
    expect(restored?.admin).toEqual(admin);
    expect(calls()).toEqual(['/auth/refresh', '/admin/me']);
  });

  it('access token hết hạn thì refresh một lần cho mọi request đang chờ', async () => {
    const { session } = await Session.login('admin@restore.test', 'x', vi.fn());
    access.clear();
    expect(await Promise.all([session.call('/x'), session.call('/y')])).toEqual([
      '/api/v1/x',
      '/api/v1/y',
    ]);
    expect(calls().filter((p) => p === '/auth/refresh')).toHaveLength(1);
  });

  it('tab khác vừa đổi cookie (REFRESH_TOKEN_REUSED) thì thử refresh lại một lần', async () => {
    const { session } = await Session.login('admin@restore.test', 'x', vi.fn());
    access.clear();
    const original = fetchMock.getMockImplementation()!;
    fetchMock.mockImplementationOnce(original);
    fetchMock.mockImplementationOnce(async () => fail(401, 'REFRESH_TOKEN_REUSED'));
    expect(await session.call('/x')).toBe('/api/v1/x');
    expect(calls().filter((p) => p === '/auth/refresh')).toHaveLength(2);
  });

  it('cookie không còn hiệu lực thì đóng phiên và báo hết hạn', async () => {
    const expired = vi.fn();
    const { session } = await Session.login('admin@restore.test', 'x', expired);
    access.clear();
    cookie = undefined;
    await expect(session.call('/x')).rejects.toThrow();
    expect(expired).toHaveBeenCalledOnce();
    await expect(session.call('/x')).rejects.toThrow('Phiên đăng nhập đã kết thúc.');
  });

  it('máy chủ lỗi 5xx khi mở lại phiên thì giữ cookie để thử lại', async () => {
    cookie = 'r0';
    me = () => fail(503);
    await expect(Session.restore(vi.fn())).rejects.toThrow('Lỗi 503');
    expect(cookie).toBe('r1');
    expect(calls()).not.toContain('/auth/logout');
  });

  it('bị thu quyền admin (403) khi mở lại phiên thì đăng xuất', async () => {
    cookie = 'r0';
    me = () => fail(403);
    await expect(Session.restore(vi.fn())).rejects.toThrow('Lỗi 403');
    expect(cookie).toBeUndefined();
  });

  it('đăng xuất đóng phiên kể cả khi máy chủ không phản hồi', async () => {
    const { session } = await Session.login('admin@restore.test', 'x', vi.fn());
    fetchMock.mockRejectedValue(new TypeError('Failed to fetch'));
    await expect(session.logout()).rejects.toThrow(TypeError);
    await expect(session.call('/admin/me')).rejects.toThrow('Phiên đăng nhập đã kết thúc.');
  });
});
