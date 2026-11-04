import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx, expect } = useApi('home');

test('users: profile', async () => {
  const { api, tokens } = ctx;
  expect('users/me', await api.get('/users/me', { token: tokens.buyer }));
  expect('users/me admin', await api.get('/users/me', { token: tokens.admin }));
  expect('users/me guest', await api.get('/users/me'));
  expect('users/me bad token', await api.get('/users/me', { token: 'not-a-jwt' }));
});

test('home: area and banners', async () => {
  const { api, tokens } = ctx;
  expect('area default', await api.get('/home/area'));
  expect('area by province', await api.get('/home/area?provinceCode=79'));
  expect('area by gps', await api.get('/home/area?latitude=10.78&longitude=106.70', { token: tokens.buyer }));
  expect('area unknown province', await api.get('/home/area?provinceCode=xx'));
  expect('area half coordinates', await api.get('/home/area?latitude=10'));
  expect('banners', await api.get('/home/banners'));
});

test('home: admin banners', async () => {
  const { api, tokens } = ctx;
  const body = { title: 'Banner mới', imageUrl: 'https://cdn.restore.test/new.jpg', route: '/ai-assistant', sortOrder: 0 };
  expect('admin banners as user', await api.get('/home/admin/banners', { token: tokens.buyer }));
  expect('admin banners', await api.get('/home/admin/banners', { token: tokens.admin }));
  expect('create banner without json', await api.post('/home/admin/banners', { token: tokens.admin, raw: 'title=x', contentType: 'text/plain' }));
  expect('create banner invalid route', await api.post('/home/admin/banners', { token: tokens.admin, body: { ...body, route: 'https://evil.test' } }));
  const created = expect('create banner', await api.post('/home/admin/banners', { token: tokens.admin, body }));
  const id = created.body.data.id;
  expect('update banner', await api.put(`/home/admin/banners/${id}`, { token: tokens.admin, body: { active: false } }));
  expect('banners after update', await api.get('/home/banners'));
  expect('delete banner', await api.delete(`/home/admin/banners/${id}`, { token: tokens.admin }));
  expect('delete missing banner', await api.delete(`/home/admin/banners/${id}`, { token: tokens.admin }));
});
