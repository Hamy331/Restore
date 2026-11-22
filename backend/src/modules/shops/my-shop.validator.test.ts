import assert from 'node:assert/strict';
import { test } from 'node:test';
import { shopNameProblem } from './my-shop.validator.js';

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
