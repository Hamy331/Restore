import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx, expect } = useApi('catalog');

test('catalog: public reference data', async () => {
  const { api } = ctx;
  expect('categories', await api.get('/catalog/categories'));
  expect('conditions', await api.get('/catalog/conditions'));
  expect('provinces', await api.get('/catalog/locations/provinces'));
  expect('wards', await api.get('/catalog/locations/provinces/79/wards'));
  expect('wards unknown province', await api.get('/catalog/locations/provinces/xx/wards'));
  expect('reverse geocode', await api.get('/catalog/locations/reverse-geocode?latitude=10.7769&longitude=106.7009'));
  expect('reverse geocode outside', await api.get('/catalog/locations/reverse-geocode?latitude=0&longitude=0'));
  expect('store categories', await api.get('/stores/categories'));
  expect('store packages', await api.get('/stores/packages'));
  expect('promotion packages', await api.get('/promotions/packages'));
  expect('unknown route', await api.get('/does-not-exist'));
});
