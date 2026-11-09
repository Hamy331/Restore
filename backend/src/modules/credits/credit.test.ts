import assert from 'node:assert/strict';
import test from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { parse } from '../../common/validation/schemas.js';
import { sandboxEnabled, summarizeWallet, topupCode, vietQrAccount, vietQrImageUrl } from './credit.type.js';
import { historyQuery, topupBody } from './credit.validator.js';

const code = (fn: () => unknown) => {
  try { fn(); } catch (error) { return (error as AppError).code + ':' + (error as AppError).field; }
  return 'ok';
};

test('wallet sums paid and bonus credits, never negative', () => {
  const expiry = new Date('2027-01-31T00:00:00Z');
  assert.deepEqual(summarizeWallet([{ bucket: 'PAID', amount: 95 }, { bucket: 'BONUS', amount: 30 }], expiry),
    { available: 125, paid: 95, bonus: 30, held: 0, nextBonusExpiry: expiry });
  assert.deepEqual(summarizeWallet([{ bucket: 'PAID', amount: -3 }], expiry),
    { available: 0, paid: 0, bonus: 0, held: 0, nextBonusExpiry: null });
});

test('topup code is RS + 6 unambiguous characters', () => {
  const value = topupCode();
  assert.match(value, /^RS[A-HJ-NP-Z2-9]{6}$/);
  assert.equal(topupCode(() => 0), 'RSAAAAAA');
});

test('VietQR needs all three env values and encodes amount and content', () => {
  assert.equal(vietQrAccount({ VIETQR_BANK_BIN: '970436' }), null);
  const account = vietQrAccount({ VIETQR_BANK_BIN: '970436', VIETQR_ACCOUNT_NO: '0123', VIETQR_ACCOUNT_NAME: 'RESTORE' })!;
  const url = vietQrImageUrl(account, 100000, 'RS8F2K1X');
  assert.ok(url.startsWith('https://img.vietqr.io/image/970436-0123-compact2.png?'));
  assert.ok(url.includes('amount=100000') && url.includes('addInfo=RS8F2K1X'));
});

test('sandbox is off in production and in live mode', () => {
  assert.equal(sandboxEnabled({}), true);
  assert.equal(sandboxEnabled({ NODE_ENV: 'production' }), false);
  assert.equal(sandboxEnabled({ PAYMENT_MODE: 'live' }), false);
});

test('topup body checks package and method', () => {
  assert.equal(code(() => parse(topupBody, { packageId: 'p100', method: 'VNPAY' })), 'ok');
  assert.equal(code(() => parse(topupBody, { packageId: 'p100', method: 'CASH' })), 'INVALID_TOPUP:method');
  assert.equal(code(() => parse(topupBody, { method: 'VIETQR' })), 'INVALID_TOPUP:packageId');
});

test('history query defaults and rejects bad filters', () => {
  assert.deepEqual(parse(historyQuery, {}), { page: 1, limit: 20, type: undefined });
  assert.deepEqual(parse(historyQuery, { page: '2', limit: '10', type: 'refund' }), { page: 2, limit: 10, type: 'refund' });
  assert.equal(code(() => parse(historyQuery, { type: 'hack' })), 'INVALID_QUERY:type');
  assert.equal(code(() => parse(historyQuery, { limit: '500' })), 'INVALID_QUERY:limit');
});
