// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { WorkspaceContext } from '../../app/workspace';
import type { Session } from '../../shared/api/session';
import { ShopVerification } from './ShopVerification';

afterEach(cleanup);

const shop = (verified: boolean) => ({
  id: 's1',
  name: 'Nội Thất Mới',
  tagline: '',
  description: '',
  address: null,
  createdAt: '2026-11-20T08:00:00Z',
  verificationType: verified ? 'CERTIFIED' : null,
  verifiedAt: verified ? '2026-11-21T08:00:00Z' : null,
  certificateCode: verified ? 'RS-2026-00042' : null,
  owner: { id: 'u1', fullName: 'Chủ Shop', email: 'chu@example.com', status: 'ACTIVE' },
  plan: { tier: 'PRO', endsAt: '2026-12-20T08:00:00Z' },
});

function open(verified: boolean) {
  const call = vi.fn((path: string) =>
    Promise.resolve(path.startsWith('/admin/shops?') ? { items: [shop(verified)], total: 1, page: 1, pending: 1 } : {}),
  );
  render(
    <WorkspaceContext.Provider value={{ canOpen: () => false, openSection: () => {}, filter: '' }}>
      <ShopVerification session={{ call } as unknown as Session} />
    </WorkspaceContext.Provider>,
  );
  return call;
}

it('mặc định xem shop chờ xác minh; xác minh gửi loại đã chọn', async () => {
  const call = open(false);
  await waitFor(() => expect(call).toHaveBeenCalledWith('/admin/shops?page=1&status=PENDING&q='));
  fireEvent.click(await screen.findByRole('button', { name: 'Xác minh' }));
  fireEvent.click(await screen.findByRole('button', { name: 'Xác minh shop' }));
  await waitFor(() =>
    expect(call).toHaveBeenCalledWith('/admin/shops/s1/verify', { type: 'CERTIFIED', reason: undefined }),
  );
});

it('thu hồi xác minh phải có lý do', async () => {
  const call = open(true);
  fireEvent.click(await screen.findByRole('button', { name: 'Thu hồi' }));
  fireEvent.click(await screen.findByRole('button', { name: 'Thu hồi xác minh' }));
  expect(await screen.findByText('Nhập từ 5 đến 300 ký tự.')).toBeTruthy();
  expect(call).not.toHaveBeenCalledWith('/admin/shops/s1/unverify', expect.anything());
});
