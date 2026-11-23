// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { WorkspaceContext } from '../../app/workspace';
import type { Session } from '../../shared/api/session';
import { Listings } from './Listings';

afterEach(cleanup);

const listing = {
  id: 'l1',
  title: 'Kệ sách gỗ',
  description: 'Mô tả',
  status: 'PENDING',
  images: [],
  updatedAt: '2026-11-20T08:00:00Z',
  owner: {
    fullName: 'Chủ Shop',
    email: 'chu@example.com',
    planTier: 'PRO',
    shop: { name: 'Nội Thất', status: 'APPROVED', verified: true },
  },
};

function open() {
  const call = vi.fn().mockResolvedValue({ items: [listing], total: 1 });
  render(
    <WorkspaceContext.Provider value={{ canOpen: () => true, openSection: () => {}, filter: '' }}>
      <Listings session={{ call } as unknown as Session} />
    </WorkspaceContext.Provider>,
  );
  return call;
}

it('hiện gói và shop của người đăng', async () => {
  open();
  expect(await screen.findByText('Cửa hàng Pro')).toBeTruthy();
  expect(screen.getByText('Shop uy tín')).toBeTruthy();
});

it('lọc theo gói và tìm theo người đăng gửi đúng tham số', async () => {
  const call = open();
  await waitFor(() => expect(call).toHaveBeenCalledWith('/admin/listings?page=1&q=&status=PENDING'));
  fireEvent.mouseDown(screen.getByLabelText('Gói của người đăng'));
  fireEvent.click(await screen.findByTitle('Bán chuyên'));
  await waitFor(() => expect(call).toHaveBeenLastCalledWith('/admin/listings?page=1&q=&tier=BASIC&status=PENDING'));
  const search = screen.getByLabelText('Tìm tin hoặc người đăng');
  fireEvent.change(search, { target: { value: 'chu@example.com' } });
  fireEvent.keyDown(search, { key: 'Enter', code: 'Enter', keyCode: 13 });
  await waitFor(() =>
    expect(call).toHaveBeenLastCalledWith('/admin/listings?page=1&q=chu%40example.com&tier=BASIC&status=PENDING'),
  );
});
