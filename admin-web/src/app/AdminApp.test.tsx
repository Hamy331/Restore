// @vitest-environment jsdom
import '../test/dom';
import { afterEach, beforeEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { AdminApp } from './AdminApp';

const ok = (data: unknown) => new Response(JSON.stringify({ success: true, data }), { status: 200 });
const fail = (status: number) =>
  new Response(JSON.stringify({ success: false, error: 'Lỗi ' + status }), { status });
let permissions: string[];
let cookie: string | undefined; // cookie refresh httpOnly mà trình duyệt giữ

beforeEach(() => {
  cookie = undefined;
  sessionStorage.clear();
  window.location.hash = '';
  permissions = ['admin:access', 'content:manage'];
  // Máy chủ giả: chỉ trả những API màn hình cần, còn lại báo lỗi để mục hiện thông báo lỗi
  vi.stubGlobal(
    'fetch',
    vi.fn(async (url: string) => {
      const path = url.replace('/api/v1', '');
      if (path === '/auth/login') {
        cookie = 'r1';
        return ok({ accessToken: 'a1' });
      }
      if (path === '/auth/refresh') return cookie ? ok({ accessToken: 'a2' }) : fail(401);
      if (path === '/auth/logout') {
        cookie = undefined;
        return ok(null);
      }
      if (path === '/admin/me') return ok({ fullName: 'Quản trị', email: 'a@restore.test', permissions });
      if (path.startsWith('/admin/knowledge?')) return ok({ items: [], total: 0, page: 1 });
      return fail(503);
    }),
  );
});
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

const heading = async (text: string) =>
  expect(await screen.findByRole('heading', { level: 1, name: text })).toBeTruthy();

it('chưa đăng nhập thì hiện form đăng nhập', async () => {
  render(<AdminApp />);
  expect(await screen.findByText('Đăng nhập quản trị')).toBeTruthy();
});

it('đăng nhập xong lưu phiên và mở đúng mục trên URL', async () => {
  window.location.hash = '#knowledge';
  render(<AdminApp />);
  fireEvent.change(await screen.findByLabelText('Email'), { target: { value: 'a@restore.test' } });
  fireEvent.change(screen.getByLabelText('Mật khẩu'), { target: { value: 'x' } });
  fireEvent.click(screen.getByRole('button', { name: 'Đăng nhập' }));
  await heading('Kho tri thức');
  expect(cookie).toBe('r1');
});

it('tải lại trang thì mở lại phiên đã lưu, không hỏi đăng nhập', async () => {
  cookie = 'r1';
  window.location.hash = '#knowledge';
  render(<AdminApp />);
  await heading('Kho tri thức');
  expect(screen.queryByText('Đăng nhập quản trị')).toBeNull();
});

it('mục không có quyền trên URL thì về Tổng quan', async () => {
  permissions = ['admin:access'];
  cookie = 'r1';
  window.location.hash = '#knowledge';
  render(<AdminApp />);
  await heading('Tổng quan');
});

it('đăng xuất thì xoá cookie phiên và quay về form đăng nhập', async () => {
  cookie = 'r1';
  render(<AdminApp />);
  await heading('Tổng quan');
  fireEvent.click(screen.getByRole('button', { name: 'Đăng xuất' }));
  expect(await screen.findByText('Đăng nhập quản trị')).toBeTruthy();
  await waitFor(() => expect(cookie).toBeUndefined());
});
