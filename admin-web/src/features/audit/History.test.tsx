// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, render, screen } from '@testing-library/react';
import { WorkspaceContext } from '../../app/workspace';
import type { Session } from '../../shared/api/session';
import { TargetHistory } from './History';

afterEach(cleanup);

const entry = (id: string, action: string, reason: string) => ({
  id,
  action,
  reason,
  targetType: 'USER',
  targetId: 'u1',
  actorId: 'a1',
  actor: { fullName: 'Quản Trị', email: 'admin@example.com' },
  createdAt: '2026-11-20T08:00:00Z',
});

function open(canOpen: boolean, page: unknown) {
  const call = vi.fn().mockResolvedValue(page);
  render(
    <WorkspaceContext.Provider value={{ canOpen: () => canOpen, openSection: () => {}, filter: '' }}>
      <TargetHistory session={{ call } as unknown as Session} type="USER" id="u1" />
    </WorkspaceContext.Provider>,
  );
  return call;
}

it('hiện số lần và các lần xử lý trước của đúng thành viên', async () => {
  const call = open(true, {
    items: [entry('e2', 'SUSPEND', 'Spam tin lần hai'), entry('e1', 'WARN', 'Spam tin')],
    total: 2,
  });
  expect(await screen.findByText('Đã xử lý 2 lần')).toBeTruthy();
  expect(call).toHaveBeenCalledWith('/admin/audit?targetType=USER&targetId=u1');
  expect(screen.getByText('Cảnh cáo')).toBeTruthy();
  expect(screen.getByText(/Spam tin lần hai/)).toBeTruthy();
});

it('chưa từng bị xử lý thì nói rõ', async () => {
  open(true, { items: [], total: 0 });
  expect(await screen.findByText('Chưa từng bị xử lý')).toBeTruthy();
});

it('admin không xem được nhật ký thì không gọi API', () => {
  const call = open(false, { items: [], total: 0 });
  expect(call).not.toHaveBeenCalled();
  expect(screen.queryByLabelText('Lịch sử xử lý')).toBeNull();
});
