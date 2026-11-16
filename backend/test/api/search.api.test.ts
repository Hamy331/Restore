import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx, expect } = useApi('search');

const titles = (res: { body: { data: { title: string }[] } }) => res.body.data.map((item) => item.title);

test('search: listings ignore accents and need every word', async () => {
  const { api } = ctx;
  // "ban" khớp "Bàn gỗ sồi thật" và "Đèn bàn học cũ"; "ban go" chỉ khớp tin đầu
  const ban = expect('search ban', await api.get('/listings/search?q=ban'));
  assert.deepEqual(titles(ban).sort(), ['Bàn gỗ sồi thật', 'Đèn bàn học cũ']);
  // Phù hợp nhất: tiêu đề bắt đầu bằng từ khoá lên trước
  assert.equal(titles(ban)[0], 'Bàn gỗ sồi thật');
  assert.deepEqual(titles(expect('search ban go', await api.get('/listings/search?q=BAN%20GO'))), ['Bàn gỗ sồi thật']);
  assert.deepEqual(titles(expect('search den', await api.get('/listings/search?q=%C4%91en'))), ['Đèn bàn học cũ']);
  assert.deepEqual(titles(expect('search exchange', await api.get('/listings/search?q=&deal=exchange'))), ['Ghế xoay văn phòng']);
  assert.equal(expect('search conditions', await api.get('/listings/search?condition=NEW,USED_GOOD&sort=newest')).body.data.length, 3);
  expect('search no match', await api.get('/listings/search?q=zzz'));
  expect('search bad sort', await api.get('/listings/search?sort=cheap'));
  expect('search bad deal', await api.get('/listings/search?deal=rent'));
  expect('search nearest without location', await api.get('/listings/search?sort=nearest'));
});

test('search: history, trending and suggestions', async () => {
  const { api, tokens } = ctx;
  expect('history as guest', await api.get('/search/history'));
  // Khách tìm thì không lưu; trang 2 cũng không lưu
  await api.get('/listings/search?q=ghe');
  await api.get('/listings/search?q=tu%20lanh&page=2', { token: tokens.buyer });
  await api.get('/listings/search?q=Gh%E1%BA%BF%20xoay', { token: tokens.buyer });
  await api.get('/listings/search?q=ghe%20xoay', { token: tokens.buyer });
  await api.get('/listings/search?q=ban', { token: tokens.seller });
  const history = expect('history', await api.get('/search/history', { token: tokens.buyer }));
  // "Ghế xoay" và "ghe xoay" gộp làm một, giữ cách viết mới nhất
  assert.deepEqual(history.body.data.map((item: { keyword: string }) => item.keyword), ['ghe xoay']);

  // Từ khoá chỉ một người tìm không được gợi ý cho người khác
  const private1 = expect('suggestions private keyword', await api.get('/search/suggestions?q=gh%E1%BA%BF'));
  assert.deepEqual(private1.body.data, ['Ghế xoay văn phòng']);
  await api.get('/listings/search?q=ghe%20XOAY', { token: tokens.seller });
  const shared = expect('suggestions ghe', await api.get('/search/suggestions?q=gh%E1%BA%BF'));
  assert.deepEqual(shared.body.data, ['ghe XOAY', 'Ghế xoay văn phòng']);
  expect('suggestions empty', await api.get('/search/suggestions?q=%20'));
  const trending = expect('trending', await api.get('/search/trending'));
  assert.equal(trending.body.data[0], 'ghe XOAY');
  assert.ok(!trending.body.data.includes('ban'));

  const id = history.body.data[0].id as string;
  expect('history delete other user', await api.delete(`/search/history/${id}`, { token: tokens.seller }));
  assert.equal((await api.get('/search/history', { token: tokens.buyer })).body.data.length, 1);
  expect('history delete', await api.delete(`/search/history/${id}`, { token: tokens.buyer }));
  expect('history clear', await api.delete('/search/history', { token: tokens.seller }));
  assert.deepEqual((await api.get('/search/history', { token: tokens.seller })).body.data, []);
});
