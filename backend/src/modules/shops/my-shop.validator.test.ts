import assert from 'node:assert/strict';
import { test } from 'node:test';
import { shopNameProblem, shopUpdateBody, shopVerificationBody } from './my-shop.validator.js';

test('shopNameProblem chặn số điện thoại, đường dẫn và từ quảng cáo quá mức', () => {
  for (const name of ['Nội Thất Gỗ Việt', 'Điện thoại Minh Anh', 'Shop 2Hand Quận 10', 'Sổ tay xinh', 'Top 10 decor']) {
    assert.equal(shopNameProblem(name), null, name);
  }
  assert.equal(shopNameProblem('Shop Lan 0901 234 567'), 'PHONE');
  assert.equal(shopNameProblem('Shop Lan 0901.234.567'), 'PHONE');
  assert.equal(shopNameProblem('noithat.vn'), 'LINK');
  assert.equal(shopNameProblem('www.shoplan'), 'LINK');
  assert.equal(shopNameProblem('Điện máy SỐ 1'), 'WORDING');
  assert.equal(shopNameProblem('Đồ gỗ tốt nhất'), 'WORDING');
  assert.equal(shopNameProblem('Samsung Chính Hãng'), 'WORDING');
  assert.equal(shopNameProblem('ReStore Official'), 'WORDING');
});

test('openingHours: xếp theo thứ, null hoặc [] là xoá, chặn trùng thứ và giờ ngược', () => {
  const hours = (value: unknown) => shopUpdateBody.safeParse({ openingHours: value });
  const ok = hours([{ day: 7, open: '09:00', close: '17:00' }, { day: 1, open: '08:00', close: '21:30' }]);
  assert.ok(ok.success);
  assert.deepEqual(ok.data.openingHours?.map((item) => item.day), [1, 7]);
  assert.equal(hours([]).data?.openingHours, null);
  assert.equal(hours(null).data?.openingHours, null);
  assert.equal(shopUpdateBody.parse({}).openingHours, undefined);
  for (const bad of [
    [{ day: 1, open: '08:00', close: '12:00' }, { day: 1, open: '13:00', close: '17:00' }],
    [{ day: 2, open: '21:00', close: '08:00' }],
    [{ day: 8, open: '08:00', close: '09:00' }],
    [{ day: 1, open: '8:00', close: '24:00' }],
    'mỗi ngày',
  ]) assert.equal(hours(bad).success, false, JSON.stringify(bad));
});

test('shopVerificationBody: mã số thuế 10 số hoặc chi nhánh -001, 1-3 ảnh', () => {
  const body = (taxCode: string, documentUrls: string[] = ['/x']) =>
    shopVerificationBody.safeParse({ businessName: 'Hộ kinh doanh Gỗ Việt', taxCode, documentUrls }).success;
  assert.ok(body('0312345678'));
  assert.ok(body(' 0312345678-001 '));
  assert.equal(body('031234567'), false);
  assert.equal(body('0312345678-01'), false);
  assert.equal(body('0312345678', []), false);
  assert.equal(body('0312345678', ['/a', '/b', '/c', '/d']), false);
});
