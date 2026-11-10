import assert from 'node:assert/strict';
import test from 'node:test';
import { splitSpend } from '../credits/credit.hold.js';
import { blockOf, personalQuota } from './posting-quota.js';

const rules = [
  { id: 'phones', freeListingLimit: 1, extraListingCredits: 15 },
  { id: 'fashion', freeListingLimit: 2, extraListingCredits: 5 },
  { id: 'books', freeListingLimit: 3, extraListingCredits: 5 },
];

test('category limit is reached before the account total', () => {
  const quota = personalQuota(rules, [{ categoryId: 'phones', used: 1, recent: 1 }], 5);
  const phones = quota.categories.find((c) => c.categoryId === 'phones')!;
  assert.equal(phones.freeAvailable, false);
  assert.equal(phones.blockedBy, 'CATEGORY');
  assert.equal(phones.extraCredits, 15);
  assert.equal(quota.categories.find((c) => c.categoryId === 'fashion')!.freeAvailable, true);
  assert.deepEqual(quota.total, { used: 1, limit: 5 });
});

test('account total of 5 free listings blocks every category', () => {
  const usage = [{ categoryId: 'fashion', used: 2, recent: 2 }, { categoryId: 'books', used: 3, recent: 3 }];
  const quota = personalQuota(rules, usage, 5);
  assert.deepEqual(quota.categories.map((c) => c.blockedBy), ['TOTAL', 'CATEGORY', 'CATEGORY']);
});

test('posting and hiding repeatedly is capped at twice the slots per 30 days', () => {
  assert.equal(blockOf(0, 1, 1, 0, 5), null);
  assert.equal(blockOf(0, 1, 2, 0, 5), 'RECENT');
  assert.equal(blockOf(1, 2, 3, 1, 5), null);
  assert.equal(blockOf(1, 2, 4, 1, 5), 'RECENT');
});

test('spending takes bonus credits first', () => {
  assert.deepEqual(splitSpend(15, 10), { bonusAmount: 10, paidAmount: 5 });
  assert.deepEqual(splitSpend(5, 30), { bonusAmount: 5, paidAmount: 0 });
  assert.deepEqual(splitSpend(5, 0), { bonusAmount: 0, paidAmount: 5 });
});
