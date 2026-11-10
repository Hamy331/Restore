import assert from 'node:assert/strict';
import test from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { parse } from '../../common/validation/schemas.js';
import { gatewaySkipped, sandboxEnabled, summarizeWallet, topupCode, vietQrAccount, vietQrImageUrl } from './credit.type.js';
import { historyQuery, topupBody } from './credit.validator.js';
import { appTransId, buildCreateOrder, hmac, verifyCallback, ZALOPAY_SANDBOX_ENDPOINT, zaloPayConfig } from './credit.zalopay.js';

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
  assert.equal(code(() => parse(topupBody, { packageId: 'p100', method: 'ZALOPAY' })), 'ok');
  assert.equal(code(() => parse(topupBody, { packageId: 'p100', method: 'VNPAY' })), 'INVALID_TOPUP:method');
  assert.equal(code(() => parse(topupBody, { packageId: 'p100', method: 'CASH' })), 'INVALID_TOPUP:method');
  assert.equal(code(() => parse(topupBody, { method: 'VIETQR' })), 'INVALID_TOPUP:packageId');
});

test('history query defaults and rejects bad filters', () => {
  assert.deepEqual(parse(historyQuery, {}), { page: 1, limit: 20, type: undefined });
  assert.deepEqual(parse(historyQuery, { page: '2', limit: '10', type: 'refund' }), { page: 2, limit: 10, type: 'refund' });
  assert.equal(code(() => parse(historyQuery, { type: 'hack' })), 'INVALID_QUERY:type');
  assert.equal(code(() => parse(historyQuery, { limit: '500' })), 'INVALID_QUERY:limit');
});

const zalo = { appId: '2554', key1: 'k1', key2: 'k2', endpoint: ZALOPAY_SANDBOX_ENDPOINT, redirectUrl: 'http://localhost:3000/r', methods: ['domestic_card'] };

test('ZaloPay config needs app id and both keys, defaults to sandbox', () => {
  assert.equal(zaloPayConfig({ ZALOPAY_APP_ID: '2554', ZALOPAY_KEY1: 'a' }), null);
  const config = zaloPayConfig({ ZALOPAY_APP_ID: '2554', ZALOPAY_KEY1: 'a', ZALOPAY_KEY2: 'b', PUBLIC_API_URL: 'https://x.ngrok.app/' })!;
  assert.equal(config.endpoint, 'https://sb-openapi.zalopay.vn/v2');
  assert.equal(config.callbackUrl, 'https://x.ngrok.app/api/v1/payments/zalopay/callback');
  assert.deepEqual(config.methods, ['domestic_card']);
  assert.deepEqual(zaloPayConfig({ ZALOPAY_APP_ID: '1', ZALOPAY_KEY1: 'a', ZALOPAY_KEY2: 'b', ZALOPAY_METHODS: 'all' })!.methods, []);
  assert.equal(zaloPayConfig({ ZALOPAY_APP_ID: '1', ZALOPAY_KEY1: 'a', ZALOPAY_KEY2: 'b' })!.redirectUrl, 'http://localhost:3000/api/v1/payments/zalopay/return');
});

test('ZaloPay app_trans_id uses the Vietnam date', () => {
  assert.equal(appTransId('RSAAAAAA', new Date('2026-11-09T18:30:00Z')), '261110_RSAAAAAA');
});

test('ZaloPay create order is signed with key1 over the documented fields', () => {
  const now = new Date('2026-11-09T03:00:00Z');
  const params = buildCreateOrder(zalo, { code: 'RSAAAAAA', userId: 'u1', amountVnd: 100000, expireSeconds: 900, now });
  assert.equal(params.embed_data, '{"redirecturl":"http://localhost:3000/r","preferred_payment_method":["domestic_card"]}');
  const input = ['2554', '261109_RSAAAAAA', 'u1', '100000', String(now.getTime()), params.embed_data, '[]'].join('|');
  assert.equal(params.mac, hmac('k1', input));
  assert.equal(params.callback_url, undefined);
});

test('ZaloPay callback is accepted only with a valid key2 signature', () => {
  const data = JSON.stringify({ app_trans_id: '261109_RSAAAAAA', zp_trans_id: 240000123, amount: 100000 });
  assert.deepEqual(verifyCallback(zalo, data, hmac('k2', data)), { app_trans_id: '261109_RSAAAAAA', zp_trans_id: 240000123, amount: 100000 });
  assert.equal(verifyCallback(zalo, data, hmac('k1', data)), null);
  assert.equal(verifyCallback(zalo, data, 'abc'), null);
});

test('debug gateway skip only works while sandbox is on', () => {
  assert.equal(gatewaySkipped({ PAYMENT_SKIP_GATEWAY: 'true' }), true);
  assert.equal(gatewaySkipped({ PAYMENT_SKIP_GATEWAY: 'true', PAYMENT_MODE: 'live' }), false);
  assert.equal(gatewaySkipped({}), false);
});
