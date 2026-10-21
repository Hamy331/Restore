import assert from 'node:assert/strict';
import test from 'node:test';
import { promotionPackageInput } from './promotion.route.js';

test('promotion catalog validates bump and featured terms', () => {
  const bump = { name: 'Đẩy tin 3 ngày', kind: 'BUMP', durationDays: 3, priority: 0, price: '28000', active: true };
  assert.deepEqual(promotionPackageInput(bump), bump);
  assert.throws(() => promotionPackageInput({ ...bump, priority: 2 }), { code: 'INVALID_PROMOTION_PACKAGE' });
  assert.deepEqual(promotionPackageInput({ ...bump, kind: 'FEATURED', priority: 3 }),
    { ...bump, kind: 'FEATURED', priority: 3 });
  assert.throws(() => promotionPackageInput({ ...bump, price: '0' }), { code: 'INVALID_PROMOTION_PACKAGE' });
});
