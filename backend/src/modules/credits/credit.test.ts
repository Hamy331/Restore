import assert from 'node:assert/strict';
import test from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { parse } from '../../common/validation/schemas.js';
import { gatewaySkipped, sandboxEnabled, summarizeWallet, topupCode, vietQrAccount, vietQrImageUrl } from './credit.type.js';
import { historyQuery, topupBody } from './credit.validator.js';
import { createHmac } from 'node:crypto';
import { extractTopupCode, parseWebhook, sepayWebhookKey, verifyApiKey, verifySignature } from './credit.sepay.js';
import { appTransId, buildCreateOrder, hmac, verifyCallback, ZALOPAY_SANDBOX_ENDPOINT, zaloPayConfig, zaloPayEndpoint, appToApp } from './credit.zalopay.js';

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

test('ZaloPay stays on the sandbox endpoint unless PAYMENT_MODE is live', () => {
  const real = 'https://openapi.zalopay.vn/v2';
  assert.equal(zaloPayEndpoint({}), ZALOPAY_SANDBOX_ENDPOINT);
  assert.equal(zaloPayEndpoint({ ZALOPAY_ENDPOINT: real }), ZALOPAY_SANDBOX_ENDPOINT);
  assert.equal(zaloPayEndpoint({ ZALOPAY_ENDPOINT: real, PAYMENT_MODE: 'sandbox' }), ZALOPAY_SANDBOX_ENDPOINT);
  assert.equal(zaloPayEndpoint({ ZALOPAY_ENDPOINT: `${real}/`, PAYMENT_MODE: 'live' }), real);
});

test('ZaloPay redirect falls back to localhost when PUBLIC_API_URL is empty', () => {
  const config = zaloPayConfig({ ZALOPAY_APP_ID: '2554', ZALOPAY_KEY1: 'k1', ZALOPAY_KEY2: 'k2', PUBLIC_API_URL: '', ZALOPAY_REDIRECT_URL: '' });
  assert.equal(config?.redirectUrl, 'http://localhost:3000/api/v1/payments/zalopay/return');
  assert.equal(config?.callbackUrl, undefined);
});

test('app-to-app info is read from the ZaloPay order_url', () => {
  const order = Buffer.from(JSON.stringify({ zptranstoken: 'ACabc', appid: 2554 })).toString('base64');
  assert.deepEqual(appToApp(`https://qcgateway.zalopay.vn/openinapp?order=${order}`, {}), { appId: 2554, zpTransToken: 'ACabc', sandbox: true });
  assert.equal(appToApp(`https://qcgateway.zalopay.vn/openinapp?order=${order}`, { PAYMENT_MODE: 'live', ZALOPAY_ENDPOINT: 'https://openapi.zalopay.vn/v2' })?.sandbox, false);
  assert.equal(appToApp(null), null);
  assert.equal(appToApp('https://example.com/?order=notbase64json'), null);
});

test('SePay webhook needs the exact Apikey header', () => {
  assert.equal(sepayWebhookKey({}), null);
  assert.equal(sepayWebhookKey({ SEPAY_WEBHOOK_API_KEY: ' k1 ' }), 'k1');
  assert.equal(verifyApiKey('Apikey secret123', 'secret123'), true);
  assert.equal(verifyApiKey('apikey  secret123 ', 'secret123'), true);
  assert.equal(verifyApiKey('Apikey secret124', 'secret123'), false);
  assert.equal(verifyApiKey('Bearer secret123', 'secret123'), false);
  assert.equal(verifyApiKey(undefined, 'secret123'), false);
});

test('SePay payload is parsed and the topup code found in code or content', () => {
  const sample = { id: 92704, gateway: 'MBBank', code: 'RS8F2K3X', content: 'RS8F2K3X chuyen tien', transferType: 'in', transferAmount: 50000 };
  assert.deepEqual(parseWebhook(sample), { id: '92704', transferType: 'in', amount: 50000, code: 'RS8F2K3X', content: 'RS8F2K3X chuyen tien' });
  assert.equal(parseWebhook({ id: 1, transferAmount: 'abc' }), null);
  assert.equal(parseWebhook(null), null);
  assert.equal(extractTopupCode({ code: null, content: 'MBVCB.123.rs8f2k3x.CT tu 0123' }), 'RS8F2K3X');
  assert.equal(extractTopupCode({ code: 'RS8F2K3X', content: '' }), 'RS8F2K3X');
  assert.equal(extractTopupCode({ code: null, content: 'chuyen tien an trua' }), null);
});

test('SePay HMAC signature is checked over timestamp and raw body', () => {
  const rawBody = Buffer.from('{"id":1,"content":"RSABCDEF tien Viet có dấu"}');
  const timestamp = '1795110000';
  const sign = (secret: string) => 'sha256=' + createHmac('sha256', secret).update(`${timestamp}.${rawBody.toString()}`).digest('hex');
  const base = { timestamp, rawBody, secret: 's3cret', nowSeconds: 1795110100 };
  assert.equal(verifySignature({ ...base, signature: sign('s3cret') }), true);
  assert.equal(verifySignature({ ...base, signature: sign('other') }), false);
  assert.equal(verifySignature({ ...base, signature: sign('s3cret'), nowSeconds: 1795110000 + 301 }), false);
  assert.equal(verifySignature({ ...base, signature: undefined }), false);
  assert.equal(verifySignature({ ...base, signature: sign('s3cret'), rawBody: undefined }), false);
});
