import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Session } from './session';

const key = 'restore-admin-session';
const admin = { fullName: 'Quản trị', email: 'admin@restore.test', permissions: ['admin:access'] };
const ok = (data: unknown) => new Response(JSON.stringify({ success: true, data }), { status: 200 });
const fail = (status: number) =>
  new Response(JSON.stringify({ success: false, error: 'Lỗi ' + status }), { status });

let storage: Map<string, string>;
let fetchMock: ReturnType<typeof vi.fn>;
// Mỗi request đi qua đây: trả về Response theo đường dẫn và access token đang gửi
function serve(handle: (path: string, token?: string, body?: any) => Response | Promise<Response>) {
  fetchMock.mockImplementation(async (url: string, init: RequestInit) => {
    const token = new Headers(init.headers).get('Authorization')?.replace('Bearer ', '');
    const body = typeof init.body === 'string' ? JSON.parse(init.body) : undefined;
    return handle(url.replace('/api/v1', ''), token, body);
  });
}
const saved = () => JSON.parse(storage.get(key) ?? 'null');
const paths = () => fetchMock.mock.calls.map(([url]) => url.replace('/api/v1', ''));

beforeEach(() => {
  storage = new Map();
  vi.stubGlobal('sessionStorage', {
    getItem: (k: string) => storage.get(k) ?? null,
    setItem: (k: string, v: string) => storage.set(k, v),
    removeItem: (k: string) => storage.delete(k),
  });
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
});

describe('Session', () => {
  it('đăng nhập lưu token, tải lại trang mở lại đúng phiên', async () => {
    serve((path, token) => {
      if (path === '/auth/login') return ok({ accessToken: 'a1', refreshToken: 'r1' });
      if (path === '/admin/me' && token === 'a1') return ok(admin);
      return fail(401);
    });
    await Session.login('admin@restore.test', 'x', vi.fn());
    expect(saved()).toEqual({ accessToken: 'a1', refreshToken: 'r1' });

    const restored = await Session.restore(vi.fn());
    expect(restored?.admin).toEqual(admin);
  });

  it('tài khoản không có quyền admin thì không lưu phiên', async () => {
    serve((path) => {
      if (path === '/auth/login') return ok({ accessToken: 'a1', refreshToken: 'r1' });
      if (path === '/admin/me') return ok({ ...admin, permissions: [] });
      return ok(null);
    });
    await expect(Session.login('user@restore.test', 'x', vi.fn())).rejects.toThrow('quyền quản trị');
    expect(storage.has(key)).toBe(false);
    expect(paths()).toContain('/auth/logout');
  });

  it('không có phiên đã lưu thì không gọi máy chủ', async () => {
    expect(Session.hasStored()).toBe(false);
    expect(await Session.restore(vi.fn())).toBeUndefined();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('access token hết hạn thì refresh, lưu token mới và gọi lại', async () => {
    storage.set(key, JSON.stringify({ accessToken: 'old', refreshToken: 'r1' }));
    serve((path, token, body) => {
      if (path === '/auth/refresh' && body.refreshToken === 'r1')
        return ok({ accessToken: 'a2', refreshToken: 'r2' });
      if (path === '/admin/me' && token === 'a2') return ok(admin);
      return fail(401);
    });
    const restored = await Session.restore(vi.fn());
    expect(restored?.admin).toEqual(admin);
    expect(saved()).toEqual({ accessToken: 'a2', refreshToken: 'r2' });
  });

  it('nhiều request cùng gặp 401 chỉ refresh một lần', async () => {
    storage.set(key, JSON.stringify({ accessToken: 'a1', refreshToken: 'r1' }));
    let current = 'a1';
    serve((path, token) => {
      if (path === '/auth/refresh') return ok({ accessToken: 'a3', refreshToken: 'r3' });
      if (path === '/admin/me') return ok(admin);
      return token === current ? ok(path) : fail(401);
    });
    const { session } = (await Session.restore(vi.fn()))!;
    current = 'a3';
    expect(await Promise.all([session.call('/x'), session.call('/y')])).toEqual(['/x', '/y']);
    expect(paths().filter((p) => p === '/auth/refresh')).toHaveLength(1);
  });

  it('refresh token bị từ chối thì xoá phiên và báo hết hạn', async () => {
    storage.set(key, JSON.stringify({ accessToken: 'old', refreshToken: 'bad' }));
    serve(() => fail(401));
    const expired = vi.fn();
    await expect(Session.restore(expired)).rejects.toThrow();
    expect(expired).toHaveBeenCalledOnce();
    expect(storage.has(key)).toBe(false);
  });

  it('mất mạng hoặc máy chủ lỗi 5xx thì giữ phiên để thử lại', async () => {
    const tokens = JSON.stringify({ accessToken: 'a1', refreshToken: 'r1' });
    storage.set(key, tokens);
    fetchMock.mockRejectedValue(new TypeError('Failed to fetch'));
    await expect(Session.restore(vi.fn())).rejects.toThrow(TypeError);
    expect(storage.get(key)).toBe(tokens);

    serve(() => fail(503));
    await expect(Session.restore(vi.fn())).rejects.toThrow('Lỗi 503');
    expect(storage.get(key)).toBe(tokens);
  });

  it('phiên đã lưu nhưng bị thu quyền admin thì xoá phiên', async () => {
    storage.set(key, JSON.stringify({ accessToken: 'a1', refreshToken: 'r1' }));
    serve((path) => (path === '/admin/me' ? fail(403) : ok(null)));
    await expect(Session.restore(vi.fn())).rejects.toThrow('Lỗi 403');
    expect(storage.has(key)).toBe(false);
  });

  it('đăng xuất xoá phiên kể cả khi máy chủ không phản hồi', async () => {
    serve((path) => (path === '/auth/login' ? ok({ accessToken: 'a1', refreshToken: 'r1' }) : ok(admin)));
    const { session } = await Session.login('admin@restore.test', 'x', vi.fn());
    fetchMock.mockRejectedValue(new TypeError('Failed to fetch'));
    await expect(session.logout()).rejects.toThrow(TypeError);
    expect(storage.has(key)).toBe(false);
    await expect(session.call('/admin/me')).rejects.toThrow('Phiên đăng nhập đã kết thúc.');
  });
});
