// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import type { Session } from '../../shared/api/session';
import { BannedTerms } from './BannedTerms';

afterEach(cleanup);

it('thêm từ gửi đúng loại, bỏ từ gọi DELETE rồi tải lại', async () => {
  const call = vi.fn((path: string, body?: unknown) =>
    Promise.resolve(body ? {} : [{ id: 't1', term: 'kakaotalk', code: 'CONTACT', createdAt: '2026-11-23T00:00:00Z' }]),
  );
  const remove = vi.fn().mockResolvedValue(undefined);
  render(<BannedTerms session={{ call, delete: remove } as unknown as Session} />);
  expect(await screen.findByText('kakaotalk')).toBeTruthy();
  expect(screen.getByText('Liên hệ ngoài')).toBeTruthy();

  fireEvent.change(screen.getByLabelText('Từ hoặc cụm từ'), { target: { value: 'hàng lậu' } });
  fireEvent.click(screen.getByRole('button', { name: 'Thêm' }));
  await waitFor(() => expect(call).toHaveBeenCalledWith('/admin/banned-terms', { term: 'hàng lậu', code: 'BANNED' }));

  const drop = screen.getByRole('button', { name: 'Bỏ' }) as HTMLButtonElement;
  await waitFor(() => expect(drop.disabled).toBe(false));
  fireEvent.click(drop);
  await screen.findByText('Bỏ "kakaotalk" khỏi bộ lọc?');
  fireEvent.click(screen.getAllByRole('button', { name: 'Bỏ' }).at(-1)!);
  await waitFor(() => expect(remove).toHaveBeenCalledWith('/admin/banned-terms/t1'));
});
