import assert from 'node:assert/strict';
import { test } from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { assertNoContentFlags, contentFlags } from './content-flags.js';

const codes = (...texts: string[]) => contentFlags(...texts).map((flag) => flag.code);

test('contentFlags: phone numbers and off-app contact', () => {
  assert.deepEqual(contentFlags('Bàn gỗ', 'Gọi 0912 345 678 nhé'), [{ code: 'CONTACT', match: '0912 345 678' }]);
  assert.deepEqual(codes('Liên hệ +84.912.345.678'), ['CONTACT']);
  assert.deepEqual(codes('Ib Zalo để xem thêm ảnh'), ['CONTACT']);
  // Giá tiền, số đo không phải số điện thoại
  assert.deepEqual(codes('Giá 1.200.000đ, kích thước 120x60, mua 2019'), []);
  assert.deepEqual(codes('Mã sản phẩm 01234567891234'), []);
});

test('contentFlags: links and domains', () => {
  assert.deepEqual(contentFlags('Xem thêm tại https://shopee.vn/abc'), [{ code: 'LINK', match: 'https://shopee.vn/abc' }]);
  assert.deepEqual(codes('Ghé www.banghe.com'), ['LINK']);
  assert.deepEqual(codes('Shop banghe.vn có nhiều mẫu'), ['LINK']);
  assert.deepEqual(codes('Cao 1.5m, rộng 0.8m'), []);
});

test('contentFlags: banned goods as whole words, with or without accents', () => {
  assert.deepEqual(contentFlags('Bán súng hơi'), [{ code: 'BANNED', match: 'súng' }]);
  assert.deepEqual(codes('Giày REPLICA đẹp'), ['BANNED']);
  assert.deepEqual(codes('Hang fake loai 1'), ['BANNED']);
  // Từ chứa từ cấm bên trong không bị gắn: "tripod", "podcast", "phao bơi"
  assert.deepEqual(codes('Chân tripod máy ảnh, micro podcast, phao bơi trẻ em'), []);
});

test('contentFlags: one flag per kind, clean text has none', () => {
  assert.deepEqual(codes('Súng nước', 'Zalo 0987654321, xem banghe.vn'), ['CONTACT', 'LINK', 'BANNED']);
  assert.deepEqual(codes('Ghế xoay văn phòng còn mới', null as unknown as string), []);
});

test('assertNoContentFlags: chặn tin bị gắn cờ trừ khi người dùng đã đồng ý gửi', () => {
  assert.throws(() => assertNoContentFlags(false, 'Bán xe', 'Gọi 0912345678'),
    (error: AppError) => error.code === 'CONTENT_FLAGGED' && error.statusCode === 409);
  assert.doesNotThrow(() => assertNoContentFlags(true, 'Bán xe', 'Gọi 0912345678'));
  assert.doesNotThrow(() => assertNoContentFlags(false, 'Bán xe', 'Xe còn tốt'));
});
