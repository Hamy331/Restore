import assert from 'node:assert/strict';
import test from 'node:test';
import { addDays, approvedExpiry, boostPrice, canExtend, featurePrice, daysLeft, extendedExpiry, isExpired, normalizeTitle } from './listing-lifecycle.js';

const now = new Date('2026-11-11T00:00:00Z');

test('expiry: null never expires, past date does', () => {
  assert.equal(isExpired(null, now), false);
  assert.equal(isExpired(addDays(now, -1), now), true);
  assert.equal(isExpired(addDays(now, 1), now), false);
});

test('approval keeps a running expiry, otherwise starts a new period', () => {
  const running = addDays(now, 10);
  assert.equal(approvedExpiry(running, now, 30), running);
  assert.deepEqual(approvedExpiry(addDays(now, -2), now, 30), addDays(now, 30));
  assert.deepEqual(approvedExpiry(null, now, 60), addDays(now, 60));
});

test('extend only within one period and adds to the remaining time', () => {
  assert.equal(canExtend(addDays(now, 31), now, 30), false);
  assert.equal(canExtend(addDays(now, 30), now, 30), true);
  assert.deepEqual(extendedExpiry(addDays(now, 5), now, 30), addDays(now, 35));
  assert.deepEqual(extendedExpiry(addDays(now, -5), now, 30), addDays(now, 30));
  assert.equal(daysLeft(addDays(now, 4.2), now), 5);
});

test('titles match regardless of accents, case and punctuation', () => {
  assert.equal(normalizeTitle('Điện thoại  iPhone 13 - Pro!'), normalizeTitle('dien thoai iphone 13 pro'));
  assert.notEqual(normalizeTitle('iPhone 13'), normalizeTitle('iPhone 14'));
});

test('boost price: tier discount, rounded, never below 1 xu', () => {
  assert.equal(boostPrice(10, 0), 10);
  assert.equal(boostPrice(10, 20), 8);
  assert.equal(boostPrice(6, 30), 4);
  assert.equal(boostPrice(4, 30), 3);
  assert.equal(boostPrice(1, 90), 1);
});

test('feature price scales by category group and plan discount', () => {
  assert.deepEqual([20000, 57000, 126000].map((p) => featurePrice(p, 10, 0)), [20, 57, 126]);
  assert.deepEqual([20000, 57000, 126000].map((p) => featurePrice(p, 6, 0)), [12, 34, 76]);
  assert.deepEqual([20000, 57000, 126000].map((p) => featurePrice(p, 4, 0)), [8, 23, 50]);
  assert.equal(featurePrice(20000, 10, 20), 16);
  assert.equal(featurePrice(126000, 4, 30), 35);
});
