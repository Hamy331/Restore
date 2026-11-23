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
  flags: [{ code: 'CONTACT', match: '0912 345 678' }],
  flagged: true,
  priceWarning: { reason: 'BELOW_TYPICAL', typical: '5000000' },
  owner: {
    fullName: 'Chủ Shop',
    email: 'chu@example.com',
    planTier: 'PRO',
    shop: { name: 'Nội Thất', status: 'APPROVED', verified: true },
    history: { rejected: 2, changesRequested: 0, removed: 1, recentStrikes: 3 },
  },
};

function open() {
  const call = vi.fn((path: string) =>
    Promise.resolve(
      path.endsWith('/seller-history')
        ? { rejected: 2, changesRequested: 0, removed: 1, recent: [
            { listingId: 'l0', title: 'Tủ cũ', action: 'REJECT', reason: 'Ghi số điện thoại', createdAt: '2026-11-01T08:00:00Z' },
          ] }
        : { items: [listing], total: 1 },
    ),
  );
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

it('tin bị gắn cờ có thẻ, chi tiết nói rõ đoạn bị khớp, lọc chỉ tin bị gắn cờ', async () => {
  const call = open();
  expect(await screen.findByText('Có SĐT / liên hệ ngoài')).toBeTruthy();
  fireEvent.click(screen.getByText('Chỉ tin bị gắn cờ (SĐT, link, hàng cấm)'));
  await waitFor(() => expect(call).toHaveBeenLastCalledWith('/admin/listings?page=1&q=&flagged=1&status=PENDING'));
  fireEvent.click(screen.getByRole('button', { name: 'Xem tin' }));
  expect(await screen.findByText('Tin bị gắn cờ tự động')).toBeTruthy();
  expect(screen.getByText('“0912 345 678”')).toBeTruthy();
  expect(screen.getByText('Bỏ qua cảnh báo')).toBeTruthy();
  expect(screen.getByText('Giá bất thường')).toBeTruthy();
  expect(screen.getByText(/Giá thấp hơn nhiều so với giá thường gặp/)).toBeTruthy();
  expect(screen.getByText('Người đăng đã được cảnh báo nhưng vẫn gửi.')).toBeTruthy();
});

it('người đăng từng vi phạm có thẻ đỏ, chi tiết liệt kê lý do gần đây', async () => {
  const call = open();
  expect(await screen.findByText('Từng bị từ chối 2, bị gỡ 1 lần')).toBeTruthy();
  expect(screen.getByText('Tái phạm')).toBeTruthy();
  fireEvent.click(screen.getByText('Chỉ người đăng tái phạm (từ 3 lần bị từ chối / gỡ trong 30 ngày)'));
  await waitFor(() => expect(call).toHaveBeenLastCalledWith('/admin/listings?page=1&q=&offender=1&status=PENDING'));
  fireEvent.click(screen.getByRole('button', { name: 'Xem tin' }));
  expect(await screen.findByText(/Ghi số điện thoại/)).toBeTruthy();
  expect(screen.getByText(/Tủ cũ/)).toBeTruthy();
  expect(call).toHaveBeenCalledWith('/admin/listings/l1/seller-history');
});
