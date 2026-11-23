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
  // Gõ không dấu thì bỏ dấu cả "đ"; gõ có dấu thì so đúng dấu ("đen" không khớp "Đèn")
  assert.deepEqual(titles(expect('search den', await api.get('/listings/search?q=den'))), ['Đèn bàn học cũ']);
  assert.deepEqual(titles(expect('search den accented', await api.get('/listings/search?q=%C4%91en'))), []);
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
  // Gõ không dấu để khớp cả từ khoá "ghe XOAY" (gõ có dấu thì chỉ khớp chữ có dấu)
  const shared = expect('suggestions ghe', await api.get('/search/suggestions?q=ghe'));
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

test('search: shops and users by name or username', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  await prisma.user.update({ where: { id: 'user-seller' }, data: { fullName: 'Trần Thị Bích', username: 'bich.shop' } });
  await prisma.user.update({ where: { id: 'user-buyer' }, data: { fullName: 'Nguyễn Văn Bình', username: 'binh_nguyen' } });
  await prisma.user.update({ where: { id: 'user-admin' }, data: { fullName: 'Bình Admin' } });
  await prisma.user.update({ where: { id: 'user-banned' }, data: { fullName: 'Bình Bị Khoá' } });
  await prisma.shop.create({ data: {
    id: 'shop-seller', ownerId: 'user-seller', name: 'Nội Thất Bích', verificationType: 'CERTIFIED', verifiedAt: new Date(), categoryIds: ['furniture'],
  } });
  await prisma.shop.create({ data: { id: 'shop-hidden', ownerId: 'user-admin', name: 'Nội Thất Chưa Duyệt', categoryIds: [] } });
  await prisma.userFollow.create({ data: { followerId: 'user-buyer', followingId: 'user-seller' } });

  const ids = (res: { body: { data: { id: string }[] } }) => res.body.data.map((item) => item.id);

  // Shop: không dấu, đủ mọi từ; shop chưa xác minh không hiện
  const shops = await api.get('/search/shops?q=noi%20that', { token: tokens.buyer });
  assert.equal(shops.status, 200, JSON.stringify(shops.body));
  assert.deepEqual(ids(shops), ['shop-seller']);
  // Theo dõi chủ shop = theo dõi shop: cùng trạng thái và số người theo dõi
  assert.deepEqual(
    [shops.body.data[0].listingCount, shops.body.data[0].isFollowing, shops.body.data[0].followerCount, shops.body.data[0].ownerUsername],
    [3, true, 1, 'bich.shop'],
  );
  assert.equal(shops.body.pagination.totalItems, 1);
  assert.deepEqual(ids(await api.get('/search/shops?q=bich')), ['shop-seller']);
  // Tên chủ shop cũng ra shop
  assert.deepEqual(ids(await api.get('/search/shops?q=tran%20thi')), ['shop-seller']);
  // Trùng username chủ shop cũng ra shop
  assert.deepEqual(ids(await api.get('/search/shops?q=bich.shop')), ['shop-seller']);
  assert.deepEqual(ids(await api.get('/search/shops?q=%40bichsh')), ['shop-seller']);
  assert.deepEqual(ids(await api.get('/search/shops?q=ban')), []);

  // Người dùng: tên không dấu hoặc username; admin và tài khoản bị khoá không hiện
  const binh = await api.get('/search/users?q=b%C3%ACnh', { token: tokens.seller });
  assert.deepEqual(ids(binh), ['user-buyer']);
  assert.equal(binh.body.data[0].isFollowing, false);
  // Chủ shop uy tín chỉ hiện một lần, ở kết quả shop
  assert.deepEqual(ids(await api.get('/search/users?q=bich', { token: tokens.buyer })), []);
  // Shop chưa xác minh thì chủ shop vẫn là người dùng bình thường
  await prisma.shop.update({ where: { id: 'shop-seller' }, data: { verificationType: null } });
  const bich = await api.get('/search/users?q=bich', { token: tokens.buyer });
  assert.deepEqual(ids(bich), ['user-seller']);
  assert.deepEqual(
    [bich.body.data[0].isFollowing, bich.body.data[0].followerCount, bich.body.data[0].listingCount, bich.body.data[0].shopId],
    [true, 1, 3, null],
  );
  assert.equal(bich.body.data[0].email, undefined, 'không lộ email');
  assert.deepEqual(ids(await api.get('/search/users?q=binh_ng')), ['user-buyer']);
  // Gõ "@" thì chỉ xét username, không xét tên hiển thị
  assert.deepEqual(ids(await api.get('/search/users?q=%40binh')), ['user-buyer']);
  assert.deepEqual(ids(await api.get('/search/users?q=%40tran')), []);
  // Trùng username đứng trước người chỉ trùng tên
  await prisma.user.update({ where: { id: 'user-seller' }, data: { fullName: 'Bình Bán Hàng', username: 'seller99' } });
  await prisma.user.update({ where: { id: 'user-buyer' }, data: { username: 'binh' } });
  assert.deepEqual(ids(await api.get('/search/users?q=binh')), ['user-buyer', 'user-seller']);
  // Phân trang, từ khoá rỗng, từ khoá sai
  const page2 = await api.get('/search/users?q=binh&page=2&limit=1');
  assert.deepEqual([ids(page2), page2.body.pagination.totalItems, page2.body.meta.hasMore], [['user-seller'], 2, false]);
  assert.deepEqual(ids(await api.get('/search/users?q=%20')), []);
  assert.equal((await api.get(`/search/users?q=${'a'.repeat(101)}`)).status, 400);
  assert.equal((await api.get('/search/shops?q=a&limit=99')).status, 400);
});
