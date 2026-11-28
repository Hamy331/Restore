import assert from 'node:assert/strict';
import { test } from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { assertNoContentFlags, contentFlags, setExtraTerms } from './content-flags.js';

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

test('contentFlags: alcohol, tobacco and stimulants, but not things that hold them', () => {
  assert.deepEqual(contentFlags('Thanh lý rượu ngoại'), [{ code: 'BANNED', match: 'rượu' }]);
  assert.deepEqual(codes('Thung bia Tiger con han'), ['BANNED']);
  assert.deepEqual(codes('Bình bóng cười'), ['BANNED']);
  assert.deepEqual(codes('Xì gà Cuba'), ['BANNED']);
  assert.deepEqual(codes('Cồn công nghiệp 90 độ'), ['BANNED']);
  assert.deepEqual(codes('Tủ rượu gỗ sồi, bộ ly rượu vang'), []);
  assert.deepEqual(codes('Sách bìa cứng', 'Sach bia cung con moi'), []);
  assert.deepEqual(codes('Cồn y tế 70 độ, bếp cồn khô'), []);
});

test('contentFlags: spelled-out, joined, invisible and look-alike characters', () => {
  assert.deepEqual(contentFlags('Bán r.ư.ợ.u nếp'), [{ code: 'BANNED', match: 'rượu' }]);
  assert.deepEqual(codes('Có m a t u y'), ['BANNED']);
  assert.deepEqual(codes('Hàng ma-túy'), ['BANNED']);
  assert.deepEqual(codes('Bán matuy'), ['BANNED']);
  assert.deepEqual(codes('Bán c4n s4'), ['BANNED']);
  assert.deepEqual(codes('Bán v@pe'), ['BANNED']);
  assert.deepEqual(codes('Bán rư​ợu'), ['BANNED']);
  assert.deepEqual(codes('Ib z.a.l.o'), ['CONTACT']);
  // Chữ viết thường, size áo, model máy không bị gắn
  assert.deepEqual(codes('Áo size S M L XL, iPhone 14 Pro 256GB, RAM 4GB'), []);
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

test('setExtraTerms: admin-added words join the built-in rules, special characters are literal', () => {
  assert.deepEqual(codes('Bán đồ chơi', 'Liên hệ qua kakaotalk'), []);
  setExtraTerms([{ term: 'kakaotalk', code: 'CONTACT' }, { term: 'c++ lậu', code: 'BANNED' }]);
  try {
    assert.deepEqual(contentFlags('Bán đồ chơi', 'Liên hệ qua KakaoTalk'), [{ code: 'CONTACT', match: 'KakaoTalk' }]);
    assert.deepEqual(codes('Sách C++ lậu'), ['BANNED']);
    assert.deepEqual(codes('Sách Cxx lậu'), [], 'ký tự đặc biệt khớp đúng chữ');
    assert.deepEqual(codes('Sách kakaotalkvn'), [], 'chỉ khớp nguyên từ');
  } finally {
    setExtraTerms([]);
  }
  assert.deepEqual(codes('Liên hệ qua kakaotalk'), []);
});
