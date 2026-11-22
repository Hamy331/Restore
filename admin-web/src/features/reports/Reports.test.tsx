// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, render, screen } from '@testing-library/react';
import { WorkspaceContext } from '../../app/workspace';
import type { Session } from '../../shared/api/session';
import { Review, type Report } from './Reports';

afterEach(cleanup);

const report = (targetType: Report['targetType']): Report => ({
  id: 'r1',
  reporterId: 'u2',
  reporter: { fullName: 'Người Báo', email: 'bao@example.com' },
  targetId: 't1',
  targetType,
  reason: 'Lừa đảo',
  evidence: '',
  status: 'OPEN',
  updatedAt: '2026-11-22T00:00:00Z',
  createdAt: '2026-11-22T00:00:00Z',
});

function open(targetType: Report['targetType'], target: unknown) {
  const call = vi.fn().mockResolvedValue(target);
  render(
    <WorkspaceContext.Provider value={{ canOpen: () => true, openSection: () => {}, filter: '' }}>
      <Review report={report(targetType)} session={{ call } as unknown as Session} close={() => {}} reload={() => {}} />
    </WorkspaceContext.Provider>,
  );
}

it('người dùng bị báo cáo: bấm được để mở hồ sơ, trạng thái bằng tiếng Việt', async () => {
  open('USER', { fullName: 'Kẻ Gian', email: 'gian@example.com', status: 'SUSPENDED', updatedAt: '' });
  expect(await screen.findByRole('button', { name: 'Kẻ Gian · gian@example.com' })).toBeTruthy();
  expect(screen.getByText(/Tạm khóa$/)).toBeTruthy();
});

it('tác giả bài viết bị báo cáo: bấm được và không hiện mã trạng thái thô', async () => {
  open('FEED_POST', {
    id: 'p1',
    text: 'Bán hàng giả',
    imageUrl: null,
    createdAt: '2026-11-22T00:00:00Z',
    updatedAt: '2026-11-22T00:00:00Z',
    author: { id: 'u3', fullName: 'Tác Giả', email: 'tacgia@example.com', status: 'ACTIVE' },
  });
  expect(await screen.findByRole('button', { name: 'Tác Giả · tacgia@example.com' })).toBeTruthy();
  expect(screen.queryByText(/ACTIVE/)).toBeNull();
  expect(screen.getByText(/Hoạt động/)).toBeTruthy();
});
