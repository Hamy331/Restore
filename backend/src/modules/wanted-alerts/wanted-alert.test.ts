import assert from 'node:assert/strict';
import test from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { parse } from '../../common/validation/schemas.js';
import { MatchableAlert, MatchableListing, matchListing, normalize, score, tokens } from './wanted-alert.matcher.js';
import { draftBody, previewQuery } from './wanted-alert.validator.js';

const draft = (body: Record<string, unknown>) => parse(draftBody, body);
const code = (fn: () => unknown) => {
  try { fn(); } catch (error) { return (error as AppError).code + ':' + (error as AppError).field; }
  return 'ok';
};

test('matcher normalizes Vietnamese text and drops filler words', () => {
  assert.equal(normalize('  Máy ẢNH   Đen '), 'may anh den');
  assert.deepEqual(tokens('Cần mua máy ảnh film Canon!'), ['may', 'anh', 'film', 'canon']);
});

test('matcher scores close titles above loose ones and tolerates small typos', () => {
  const exact = score('ghế xoay văn phòng', 'Ghế xoay văn phòng');
  const typo = score('ghe xoay van phong', 'Ghế xaoy văn phòng');
  const unrelated = score('ghế xoay văn phòng', 'Bàn gỗ sồi thật');
  assert.equal(exact, 1);
  assert.ok(typo > 0.6 && typo < 1, `typo ${typo}`);
  assert.ok(unrelated < 0.3, `unrelated ${unrelated}`);
  assert.ok(score('máy ảnh canon', 'Bán đồ cũ', 'Máy ảnh Canon AE-1 còn tốt') > 0.6, 'mô tả vẫn được tính');
  assert.equal(score('cần mua', 'Ghế xoay'), 0);
});

const alert: MatchableAlert = {
  keywords: 'ghế xoay', matchLevel: 'BALANCED', categoryId: 'furniture', minPrice: 100_000, maxPrice: 2_000_000,
  conditions: [], dealTypes: [], areaCode: '79', areaLevel: 'province', createdAt: new Date('2026-10-01T00:00:00Z'),
};
const listing: MatchableListing = {
  title: 'Ghế xoay văn phòng', description: '', price: 1_200_000, condition: 'USED_GOOD', allowSale: true, allowExchange: false,
  categoryId: 'furniture', provinceCode: '79', wardCode: '79-SG', createdAt: new Date('2026-10-02T00:00:00Z'),
};

test('matchListing applies hard filters before scoring', () => {
  assert.ok((matchListing(alert, listing) ?? 0) >= 0.45);
  assert.equal(matchListing(alert, { ...listing, createdAt: new Date('2026-09-30T00:00:00Z') }), null, 'tin cũ hơn thông báo');
  assert.equal(matchListing(alert, { ...listing, categoryId: 'books' }), null);
  assert.equal(matchListing(alert, { ...listing, price: 5_000_000 }), null);
  assert.ok(matchListing(alert, { ...listing, price: 5_000_000, allowSale: false, allowExchange: true }) != null, 'tin chỉ đổi bỏ qua giá');
  assert.equal(matchListing({ ...alert, dealTypes: ['exchange'] }, listing), null);
  assert.equal(matchListing({ ...alert, conditions: ['NEW'] }, listing), null);
  assert.equal(matchListing({ ...alert, areaCode: '01' }, listing), null);
  assert.ok(matchListing({ ...alert, areaCode: '79-SG', areaLevel: 'ward' }, listing) != null);
  assert.equal(matchListing({ ...alert, keywords: 'ghế xoay gaming màu đỏ', matchLevel: 'STRICT' }, listing), null);
});

test('draft body normalizes the app payload', () => {
  assert.deepEqual(draft({
    keywords: ' Ghế xoay ', categoryId: 'furniture', minPrice: 100000, maxPrice: '2000000', conditions: ['USED_GOOD', 'USED_GOOD'],
    dealTypes: ['buy'], area: { code: '79-SG', level: 'ward', label: 'bỏ qua' }, matchLevel: 'STRICT',
  }), {
    keywords: 'Ghế xoay', categoryId: 'furniture', minPrice: 100000, maxPrice: 2000000, conditions: ['USED_GOOD'], dealTypes: ['buy'],
    areaCode: '79-SG', areaLevel: 'ward', areaLabel: 'Phường Sài Gòn, TP. Hồ Chí Minh', matchLevel: 'STRICT',
  });
  assert.deepEqual(draft({ keywords: 'máy ảnh', categoryId: null, minPrice: null, conditions: null, area: null }), {
    keywords: 'máy ảnh', categoryId: null, minPrice: null, maxPrice: null, conditions: [], dealTypes: [],
    areaCode: null, areaLevel: null, areaLabel: null, matchLevel: 'BALANCED',
  });
  assert.equal(draft({ keywords: 'xe', area: { code: '79', level: 'province' } }).areaLabel, 'TP. Hồ Chí Minh');
});

test('draft body rejects invalid fields', () => {
  assert.equal(code(() => draft({})), 'INVALID_INPUT:keywords');
  assert.equal(code(() => draft({ keywords: 'cần mua' })), 'INVALID_INPUT:keywords');
  assert.equal(code(() => draft({ keywords: 'x'.repeat(81) })), 'INVALID_INPUT:keywords');
  assert.equal(code(() => draft({ keywords: 'xe', minPrice: 5, maxPrice: 1 })), 'INVALID_INPUT:maxPrice');
  assert.equal(code(() => draft({ keywords: 'xe', minPrice: -1 })), 'INVALID_INPUT:minPrice');
  assert.equal(code(() => draft({ keywords: 'xe', conditions: ['BROKEN'] })), 'INVALID_INPUT:conditions');
  assert.equal(code(() => draft({ keywords: 'xe', dealTypes: 'buy' })), 'INVALID_INPUT:dealTypes');
  assert.equal(code(() => draft({ keywords: 'xe', area: { code: 'nope', level: 'ward' } })), 'INVALID_LOCATION:area');
  assert.equal(code(() => draft({ keywords: 'xe', area: { code: '79', level: 'city' } })), 'INVALID_LOCATION:area');
  assert.equal(code(() => draft({ keywords: 'xe', matchLevel: 'LOOSE' })), 'INVALID_INPUT:matchLevel');
  assert.equal(code(() => draft({ keywords: 'xe', sort: 'newest' })), 'INVALID_INPUT:sort');
  assert.deepEqual(parse(previewQuery, {}), { limit: 20 });
  assert.equal(code(() => parse(previewQuery, { limit: '99' })), 'INVALID_INPUT:limit');
});
