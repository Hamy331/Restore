import assert from 'node:assert/strict';
import { test } from 'node:test';
import { priceWarning } from './price-check.js';

test('priceWarning: giá ảo, thấp hơn nhiều giá thường gặp, tin chỉ trao đổi', () => {
  assert.deepEqual(priceWarning('1000', null), { reason: 'TOO_LOW' });
  assert.equal(priceWarning('0', 5_000_000), null, 'giá 0 là tin chỉ trao đổi');
  assert.deepEqual(priceWarning('300000', 5_000_000.4), { reason: 'BELOW_TYPICAL', typical: '5000000' });
  assert.equal(priceWarning('600000', 5_000_000), null, 'trên 1/10 giá thường gặp');
  assert.equal(priceWarning('300000', null), null, 'chuyên mục chưa đủ mẫu');
  assert.equal(priceWarning('90000000', 5_000_000), null, 'giá cao không cảnh báo');
});
