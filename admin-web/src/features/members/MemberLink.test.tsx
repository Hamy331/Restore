// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { WorkspaceContext } from '../../app/workspace';
import type { Session } from '../../shared/api/session';
import { MemberLink } from './MemberLink';
import { Members } from './Members';

afterEach(cleanup);

const person = { fullName: 'Ngô Tường Phát', email: 'phat@example.com' };
const workspace = (canOpen: boolean, openSection = () => {}, filter = '') => ({
  canOpen: () => canOpen,
  openSection,
  filter,
});

it('bấm tên thì mở Thành viên, tìm theo email', () => {
  const openSection = vi.fn();
  render(
    <WorkspaceContext.Provider value={workspace(true, openSection)}>
      <MemberLink person={person} />
    </WorkspaceContext.Provider>,
  );
  fireEvent.click(screen.getByRole('button', { name: 'Ngô Tường Phát · phat@example.com' }));
  expect(openSection).toHaveBeenCalledWith('members', 'phat@example.com');
});

it('admin không có quyền Thành viên chỉ thấy chữ', () => {
  render(
    <WorkspaceContext.Provider value={workspace(false)}>
      <MemberLink person={person} />
    </WorkspaceContext.Provider>,
  );
  expect(screen.queryByRole('button')).toBeNull();
  expect(screen.getByText('Ngô Tường Phát · phat@example.com')).toBeTruthy();
});

it('Thành viên mở với email trên URL thì tìm sẵn người đó', async () => {
  const call = vi.fn().mockResolvedValue({ items: [], total: 0 });
  render(
    <WorkspaceContext.Provider value={workspace(true, () => {}, 'phat@example.com')}>
      <Members session={{ call } as unknown as Session} />
    </WorkspaceContext.Provider>,
  );
  await waitFor(() => expect(call).toHaveBeenCalled());
  const params = new URLSearchParams(call.mock.calls[0][0].split('?')[1]);
  expect(params.get('q')).toBe('phat@example.com');
  expect(params.get('status')).toBe('');
  expect((screen.getByLabelText('Tìm thành viên') as HTMLInputElement).value).toBe('phat@example.com');
});
