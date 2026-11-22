// @vitest-environment jsdom
import '../../test/dom';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { Form, Input } from 'antd';
import { ApiError } from '../api/session';
import { EditDialog } from './EditDialog';

afterEach(cleanup);

function open(save: (values: { name: string }) => Promise<unknown>) {
  const saved = vi.fn(),
    close = vi.fn(),
    onStale = vi.fn();
  render(
    <EditDialog<{ name: string }>
      title="Sửa mục"
      initialValues={{ name: 'Mục cũ' }}
      save={save}
      saved={saved}
      close={close}
      onStale={onStale}
    >
      <Form.Item name="name" label="Tên">
        <Input />
      </Form.Item>
    </EditDialog>,
  );
  const submit = () => screen.getByRole('button', { name: /Lưu thay đổi/ });
  return { saved, close, onStale, submit };
}

it('lưu xong thì tải lại danh sách và đóng hộp thoại', async () => {
  const save = vi.fn().mockResolvedValue(undefined);
  const { saved, close, submit } = open(save);
  fireEvent.change(screen.getByLabelText('Tên'), { target: { value: 'Mục mới' } });
  fireEvent.click(submit());
  await waitFor(() => expect(close).toHaveBeenCalledOnce());
  expect(save).toHaveBeenCalledWith({ name: 'Mục mới' });
  expect(saved).toHaveBeenCalledOnce();
});

it('bấm lưu hai lần khi đang gửi chỉ gửi một lần', async () => {
  let finish!: () => void;
  const save = vi.fn(() => new Promise<void>((resolve) => (finish = resolve)));
  const { close, submit } = open(save);
  fireEvent.click(submit());
  await waitFor(() => expect(save).toHaveBeenCalledOnce());
  fireEvent.click(submit());
  finish();
  await waitFor(() => expect(close).toHaveBeenCalledOnce());
  expect(save).toHaveBeenCalledOnce();
});

it('dữ liệu đã bị người khác sửa (409) thì khoá nút lưu và tải lại', async () => {
  const { saved, close, onStale, submit } = open(() =>
    Promise.reject(new ApiError(409, 'Dữ liệu đã thay đổi.')),
  );
  fireEvent.click(submit());
  expect(await screen.findByText('Dữ liệu đã thay đổi.')).toBeTruthy();
  expect(screen.getByText('Đóng cửa sổ và mở lại dữ liệu mới nhất.')).toBeTruthy();
  expect(onStale).toHaveBeenCalledOnce();
  expect(submit().hasAttribute('disabled')).toBe(true);
  expect(saved).not.toHaveBeenCalled();
  expect(close).not.toHaveBeenCalled();
});

it('lỗi khác thì hiện lỗi và cho thử lại', async () => {
  const save = vi
    .fn()
    .mockRejectedValueOnce(new ApiError(500, 'Máy chủ lỗi.'))
    .mockResolvedValueOnce(undefined);
  const { close, onStale, submit } = open(save);
  fireEvent.click(submit());
  expect(await screen.findByText('Máy chủ lỗi.')).toBeTruthy();
  expect(onStale).not.toHaveBeenCalled();
  await waitFor(() => expect(submit().hasAttribute('disabled')).toBe(false));
  fireEvent.click(submit());
  await waitFor(() => expect(close).toHaveBeenCalledOnce());
});
