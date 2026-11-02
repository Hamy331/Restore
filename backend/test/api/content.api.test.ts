import { test } from 'node:test';
import { useApi } from './support/context.js';
import { PNG } from './support/fixtures.js';

const { ctx, expect } = useApi('content');

test('content: media and blog posts', async () => {
  const { api, tokens } = ctx;
  expect('upload media as user', await api.post('/content/media', { token: tokens.buyer, raw: PNG, contentType: 'image/png' }));
  const media = expect('upload media', await api.post('/content/media', { token: tokens.admin, raw: PNG, contentType: 'image/png' }));
  const coverUrl = media.body.data.url;
  const filename = String(coverUrl).split('/').pop();
  expect('media before publish (guest)', await api.get(`/content/media/${filename}`));

  const post = { title: 'Mẹo mua đồ cũ an toàn', slug: 'meo-mua-do-cu', category: 'Hướng dẫn', content: 'Nội dung bài viết đủ dài để qua kiểm tra.', coverUrl, listingIds: ['listing-1'], status: 'PUBLISHED' };
  expect('create post invalid slug', await api.post('/admin/posts', { token: tokens.admin, body: { ...post, slug: 'Sai Slug' } }));
  const created = expect('create post', await api.post('/admin/posts', { token: tokens.admin, body: post }));
  expect('admin posts', await api.get('/admin/posts', { token: tokens.admin }));
  expect('update post', await api.put(`/admin/posts/${created.body.data.id}`, { token: tokens.admin, body: { ...post, title: 'Mẹo mua đồ cũ an toàn hơn', updatedAt: created.body.data.updatedAt } }));
  expect('update post stale', await api.put(`/admin/posts/${created.body.data.id}`, { token: tokens.admin, body: { ...post, updatedAt: created.body.data.updatedAt } }));
  expect('public posts', await api.get('/content/posts'));
  expect('public post detail', await api.get('/content/posts/meo-mua-do-cu'));
  expect('public post missing', await api.get('/content/posts/khong-co'));
  const image = await api.get(`/content/media/${filename}`);
  expect('media after publish (guest)', { ...image, body: { bytes: image.status === 200 ? PNG.length : image.body } });
});

test('content: knowledge base', async () => {
  const { api, tokens } = ctx;
  const doc = expect('create knowledge', await api.post('/admin/knowledge', { token: tokens.admin, body: { title: 'Chính sách đổi trả', content: 'Người mua có thể đổi trả trong 3 ngày.', active: true } }));
  expect('upload knowledge', await api.post('/content/knowledge/upload?title=Huong%20dan%20dang%20tin', { token: tokens.admin, raw: 'Đăng tin cần ít nhất một ảnh rõ nét.', contentType: 'text/plain' }));
  const synced = expect('sync knowledge', await api.post(`/admin/knowledge/${doc.body.data.id}/sync`, { token: tokens.admin, body: { updatedAt: doc.body.data.updatedAt } }));
  expect('catalog sync', await api.post('/admin/knowledge/catalog-sync', { token: tokens.admin }));
  expect('admin knowledge', await api.get('/admin/knowledge', { token: tokens.admin }));
  expect('search knowledge', await api.get('/content/knowledge/search?q=doi%20tra'));
  expect('search knowledge too short', await api.get('/content/knowledge/search?q=a'));
  const list = await api.get('/admin/knowledge', { token: tokens.admin });
  const current = list.body.data.items.find((item: { id: string }) => item.id === doc.body.data.id);
  const updated = expect('update knowledge', await api.put(`/admin/knowledge/${doc.body.data.id}`, { token: tokens.admin, body: { title: 'Chính sách đổi trả mới', content: 'Người mua có thể đổi trả trong 5 ngày.', active: true, updatedAt: current.updatedAt } }));
  expect('delete knowledge', await api.delete(`/admin/knowledge/${doc.body.data.id}`, { token: tokens.admin, body: { updatedAt: updated.body.data.updatedAt } }));
  void synced;
});

test('content: reports and tickets', async () => {
  const { api, tokens } = ctx;
  expect('report self', await api.post('/content/reports', { token: tokens.seller, body: { targetType: 'LISTING', targetId: 'listing-1', reason: 'Tin giả mạo', evidence: 'Ảnh lấy từ mạng.' } }));
  const report = expect('report listing', await api.post('/content/reports', { token: tokens.buyer, body: { targetType: 'LISTING', targetId: 'listing-1', reason: 'Tin giả mạo', evidence: 'Ảnh lấy từ mạng.' } }));
  expect('report duplicate', await api.post('/content/reports', { token: tokens.buyer, body: { targetType: 'LISTING', targetId: 'listing-1', reason: 'Tin giả mạo', evidence: 'Ảnh lấy từ mạng.' } }));
  expect('reports mine', await api.get('/content/reports/mine', { token: tokens.buyer }));
  expect('admin reports', await api.get('/admin/reports?status=OPEN', { token: tokens.admin }));
  expect('admin report target', await api.get(`/admin/reports/${report.body.data.id}/target`, { token: tokens.admin }));
  expect('resolve report wrong action', await api.post(`/admin/reports/${report.body.data.id}/resolve`, { token: tokens.admin, body: { action: 'BAN', reason: 'Không phù hợp', updatedAt: report.body.data.updatedAt } }));
  expect('resolve report', await api.post(`/admin/reports/${report.body.data.id}/resolve`, { token: tokens.admin, body: { action: 'DISMISS', reason: 'Ảnh là của người bán', updatedAt: report.body.data.updatedAt } }));

  const ticket = expect('create ticket', await api.post('/content/tickets', { token: tokens.buyer, body: { subject: 'Không đăng được tin', content: 'Ứng dụng báo lỗi khi đăng.' } }));
  expect('reply ticket', await api.post(`/content/tickets/${ticket.body.data.id}/reply`, { token: tokens.buyer, body: { content: 'Mình gửi thêm ảnh chụp.' } }));
  expect('reply ticket of other user', await api.post(`/content/tickets/${ticket.body.data.id}/reply`, { token: tokens.seller, body: { content: 'Xin chào' } }));
  expect('my tickets', await api.get('/content/tickets', { token: tokens.buyer }));
  const adminTickets = expect('admin tickets', await api.get('/admin/tickets', { token: tokens.admin }));
  const updatedAt = adminTickets.body.data.items[0].updatedAt;
  const reply = expect('admin reply ticket', await api.post(`/admin/tickets/${ticket.body.data.id}/reply`, { token: tokens.admin, body: { content: 'Bạn thử cập nhật ứng dụng.', updatedAt } }));
  const fresh = await api.get('/admin/tickets', { token: tokens.admin });
  expect('admin close ticket', await api.post(`/admin/tickets/${ticket.body.data.id}/status`, { token: tokens.admin, body: { status: 'RESOLVED', updatedAt: fresh.body.data.items[0].updatedAt } }));
  void reply;
});
