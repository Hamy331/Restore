import assert from 'node:assert/strict';
import test from 'node:test';
import { PLAN_PERIOD_MS, planPriceCredits, quotePlan } from './plan-pricing.js';

const now = new Date('2026-11-11T00:00:00Z');
const basic = { packageId: 'basic', priorityLevel: 1, priceCredits: 99 };
const pro = { packageId: 'pro', priorityLevel: 2, priceCredits: 299 };
const at = (days: number) => new Date(now.getTime() + days * 86_400_000);

test('plan price: VND to points, rounded up', () => {
  assert.equal(planPriceCredits(99000), 99);
  assert.equal(planPriceCredits('299500'), 300);
});

test('new plan and expired plan pay full price for 30 days', () => {
  assert.deepEqual(quotePlan(basic, null, now), { mode: 'NEW', price: 99, credit: 0, amount: 99, endsAt: new Date(now.getTime() + PLAN_PERIOD_MS) });
  assert.equal(quotePlan(basic, { ...pro, endsAt: at(-1) }, now)!.mode, 'NEW');
});

test('renew adds 30 days after the current end', () => {
  const quote = quotePlan(basic, { ...basic, endsAt: at(10) }, now)!;
  assert.deepEqual([quote.mode, quote.amount, quote.endsAt.getTime()], ['RENEW', 99, at(40).getTime()]);
});

test('upgrade credits the unused part of the old plan', () => {
  const quote = quotePlan(pro, { ...basic, endsAt: at(15) }, now)!;
  assert.deepEqual([quote.mode, quote.credit, quote.amount], ['UPGRADE', 49, 250]);
});

test('downgrade waits until the higher plan ends', () => {
  assert.equal(quotePlan(basic, { ...pro, endsAt: at(5) }, now), null);
});
