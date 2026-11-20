import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody } from './support/fixtures.js';

const { ctx } = useApi('saved-addresses');

const WARDS = ['26740', '25747', '25750', '25760'];
const address = (wardCode: string, streetAddress: string, extra: Record<string, unknown> = {}) =>
  ({ provinceCode: '79', wardCode, streetAddress, ...extra });

/** Sổ địa chỉ: lưu khi đăng tin, gộp trùng, tối đa 5 (bỏ địa chỉ lâu không dùng), đặt tên, xoá */
test('saved addresses: remembered from listings, deduped, max 5, rename, delete', async () => {
  const { api, tokens } = ctx;
  assert.equal((await api.get('/users/me/addresses')).status, 401);
  const empty = await api.get('/users/me/addresses', { token: tokens.buyer });
  assert.equal(empty.status, 200, JSON.stringify(empty.body));
  assert.deepEqual(empty.body.data, []);

  // Đăng tin thì địa chỉ của tin được lưu
  const created = await api.post('/listings', { token: tokens.buyer, body: listingBody('Quạt đứng Senko') });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  let list = (await api.get('/users/me/addresses', { token: tokens.buyer })).body.data;
  assert.equal(list.length, 1);
  assert.deepEqual([list[0].wardCode, list[0].streetAddress, list[0].ward.name, list[0].label], ['26740', '1 Đường Thử', 'Phường Sài Gòn', null]);
  assert.ok(typeof list[0].latitude === 'number' && list[0].province.code === '79');

  // Cùng phường + số nhà (khác hoa thường, dấu, khoảng trắng) là một địa chỉ
  const same = await api.post('/users/me/addresses', { token: tokens.buyer, body: address('26740', '1  duong thu', { label: 'Nhà' }) });
  assert.equal(same.status, 200, JSON.stringify(same.body));
  list = (await api.get('/users/me/addresses', { token: tokens.buyer })).body.data;
  assert.deepEqual(list.map((item: { label: string }) => item.label), ['Nhà']);

  // Lưu thêm tới 6 địa chỉ: chỉ giữ 5, bỏ địa chỉ lâu không dùng nhất ("Nhà")
  for (const [index, ward] of WARDS.entries()) {
    assert.equal((await api.post('/users/me/addresses', { token: tokens.buyer, body: address(ward, `${index + 10} Lê Lợi`) })).status, 200);
  }
  list = (await api.get('/users/me/addresses', { token: tokens.buyer })).body.data;
  assert.equal(list.length, 5);
  assert.ok(list.some((item: { label: string }) => item.label === 'Nhà'));
  assert.equal((await api.post('/users/me/addresses', { token: tokens.buyer, body: address('26740', '99 Pasteur') })).status, 200);
  list = (await api.get('/users/me/addresses', { token: tokens.buyer })).body.data;
  assert.equal(list.length, 5);
  assert.equal(list[0].streetAddress, '99 Pasteur', 'mới dùng gần nhất đứng đầu');
  assert.ok(!list.some((item: { label: string }) => item.label === 'Nhà'));

  // Đặt tên, bỏ tên, lỗi
  const id = list[1].id as string;
  const renamed = await api.patch(`/users/me/addresses/${id}`, { token: tokens.buyer, body: { label: ' Cửa hàng ' } });
  assert.deepEqual([renamed.status, renamed.body.data.label], [200, 'Cửa hàng']);
  assert.equal((await api.patch(`/users/me/addresses/${id}`, { token: tokens.buyer, body: { label: 'x'.repeat(41) } })).status, 400);
  assert.equal((await api.patch(`/users/me/addresses/${id}`, { token: tokens.seller, body: { label: 'A' } })).status, 404);
  assert.equal((await api.patch(`/users/me/addresses/${id}`, { token: tokens.buyer, body: { label: null } })).body.data.label, null);
  assert.equal((await api.post('/users/me/addresses', { token: tokens.buyer, body: address('25747', '', { provinceCode: '01' }) })).status, 400);

  // Xoá: chỉ của mình
  assert.equal((await api.delete(`/users/me/addresses/${id}`, { token: tokens.seller })).status, 404);
  assert.equal((await api.delete(`/users/me/addresses/${id}`, { token: tokens.buyer })).status, 204);
  assert.equal((await api.get('/users/me/addresses', { token: tokens.buyer })).body.data.length, 4);
  assert.deepEqual((await api.get('/users/me/addresses', { token: tokens.seller })).body.data, []);
});
