import assert from 'node:assert/strict';
import { test } from 'node:test';
import { extraDaysCredits, freeDaysFor, postingDisplayQuote, suggestedPack } from './display-pricing.js';

const packs = [{ days: 30, discountPercent: 10 }, { days: 60, discountPercent: 20 }, { days: 90, discountPercent: 30 }];
const personal = { freeDaysPercent: 100, extendDiscountPercent: 0 };
const phones = { displayDays: 30, maxDisplayDays: 120, dayPackCredits: 15 };
const pets = { displayDays: 21, maxDisplayDays: 60, dayPackCredits: 8 };
const books = { displayDays: 60, maxDisplayDays: 180, dayPackCredits: 3 };

test('day price follows the category, packs are cheaper', () => {
  assert.deepEqual([7, 30, 60, 90].map((days) => extraDaysCredits(days, phones, packs, personal)), [4, 14, 24, 32]);
  assert.deepEqual([7, 30, 60].map((days) => extraDaysCredits(days, pets, packs, personal)), [2, 8, 13]);
  assert.deepEqual([1, 30, 90].map((days) => extraDaysCredits(days, books, packs, personal)), [1, 3, 7]);
  assert.equal(extraDaysCredits(0, phones, packs, personal), 0);
  assert.equal(extraDaysCredits(31, phones, packs, personal), 16, 'ngày lẻ không được giảm theo mốc');
});

test('plans add free days and discount, capped at the category maximum', () => {
  assert.equal(freeDaysFor(phones, { freeDaysPercent: 150 }), 45);
  assert.equal(freeDaysFor(pets, { freeDaysPercent: 200 }), 42);
  assert.equal(freeDaysFor({ ...books, maxDisplayDays: 100 }, { freeDaysPercent: 200 }), 100);
  assert.equal(extraDaysCredits(30, phones, packs, { extendDiscountPercent: 30 }), 10);
});

test('suggests a pack when it costs the same or less', () => {
  assert.deepEqual(suggestedPack(28, 120, phones, packs, personal), { days: 30, credits: 14 });
  assert.equal(suggestedPack(10, 120, phones, packs, personal), null);
  assert.equal(suggestedPack(30, 120, phones, packs, personal), null);
  assert.equal(suggestedPack(58, 50, phones, packs, personal), null, 'mốc vượt tối đa thì không gợi ý');
});

test('posting quote defaults to the free days', () => {
  assert.deepEqual(postingDisplayQuote(null, phones, packs, personal), { freeDays: 30, displayDays: 30, paidDays: 0, credits: 0 });
  assert.deepEqual(postingDisplayQuote(60, phones, packs, personal), { freeDays: 30, displayDays: 60, paidDays: 30, credits: 14 });
  assert.deepEqual(postingDisplayQuote(14, phones, packs, personal), { freeDays: 30, displayDays: 14, paidDays: 0, credits: 0 });
});
