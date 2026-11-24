// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import type { Session } from '../../shared/api/session';
import { ShopReviews } from './ShopReviews';

afterEach(cleanup);

const shop = (verified: boolean) => ({
  id: 's1',
  name: 'Nội Thất Mới',
  tagline: '',
  description: '',
  address: null,
  logoUrl: null,
  coverUrl: null,
  status: 'APPROVED',
  submittedAt: '2026-11-20T08:00:00Z',
  reviewedAt: '2026-11-21T08:00:00Z',
  rejectNote: null,
  verified,
  verificationType: verified ? 'CERTIFIED' : null,
  certificateCode: verified ? 'RS-2026-00042' : null,
  categoryIds: [],
  owner: { id: 'u1', email: 'chu@example.com', fullName: 'Chủ Shop', status: 'ACTIVE' },
  planTier: 'PRO',
  planEndsAt: null,
});

function open(verified: boolean) {
  const call = vi.fn((path: string) =>
    Promise.resolve(path.startsWith('/admin/shops?') ? { pendingCount: 0, items: [shop(verified)] } : {}),
  );
  render(<ShopReviews session={{ call } as unknown as Session} />);
  return call;
}

it('shop đã duyệt xác minh được, gửi loại đã chọn', async () => {
  const call = open(false);
  fireEvent.click(await screen.findByRole('button', { name: 'Xác minh' }));
  fireEvent.click(await screen.findByRole('button', { name: 'Xác minh shop' }));
  await waitFor(() =>
    expect(call).toHaveBeenCalledWith('/admin/shops/s1/verify', { type: 'CERTIFIED', reason: undefined }),
  );
});

it('shop uy tín hiện mã chứng nhận; thu hồi phải có lý do', async () => {
  const call = open(true);
  expect(await screen.findByText('Shop uy tín · RS-2026-00042')).toBeTruthy();
  fireEvent.click(screen.getByRole('button', { name: 'Thu hồi xác minh' }));
  fireEvent.click((await screen.findAllByRole('button', { name: 'Thu hồi xác minh' })).at(-1)!);
  expect(await screen.findByText('Nhập từ 5 đến 300 ký tự.')).toBeTruthy();
  expect(call).not.toHaveBeenCalledWith('/admin/shops/s1/unverify', expect.anything());
});
