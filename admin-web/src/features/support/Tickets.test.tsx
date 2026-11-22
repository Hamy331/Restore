// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { WorkspaceContext } from '../../app/workspace';
import type { Session } from '../../shared/api/session';
import { Tickets } from './Tickets';

afterEach(cleanup);

const ticket = {
  id: 't1',
  subject: 'Không đăng được tin',
  userId: 'u1',
  status: 'OPEN',
  updatedAt: '2026-11-21T08:00:00Z',
  sender: { fullName: 'Ngô Tường Phát', email: 'phat@example.com' },
  messages: [],
};

function open(filter = '') {
  const call = vi.fn().mockResolvedValue({ items: [ticket], total: 1, page: 1 });
  render(
    <WorkspaceContext.Provider value={{ canOpen: () => true, openSection: () => {}, filter }}>
      <Tickets session={{ call } as unknown as Session} />
    </WorkspaceContext.Provider>,
  );
  return call;
}

it('mở từ menu (không có bộ lọc) thì chỉ xem yêu cầu đang mở', async () => {
  const call = open();
  await waitFor(() => expect(call).toHaveBeenCalledWith('/admin/tickets?status=OPEN&page=1'));
  expect(await screen.findByText('Ngô Tường Phát · phat@example.com')).toBeTruthy();
});

it('bộ lọc trên URL được dùng, giá trị lạ thì về Đang mở', async () => {
  const resolved = open('RESOLVED');
  await waitFor(() => expect(resolved).toHaveBeenCalledWith('/admin/tickets?status=RESOLVED&page=1'));
  cleanup();
  const junk = open('rac');
  await waitFor(() => expect(junk).toHaveBeenCalledWith('/admin/tickets?status=OPEN&page=1'));
});

it('chọn Tất cả thì bỏ lọc trạng thái', async () => {
  const call = open();
  fireEvent.click(await screen.findByText('Tất cả'));
  await waitFor(() => expect(call).toHaveBeenLastCalledWith('/admin/tickets?page=1'));
});
