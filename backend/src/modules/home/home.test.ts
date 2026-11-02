import assert from 'node:assert/strict';
import test from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { NATIONWIDE_AREA, resolveArea } from './home.service.js';
import { parse } from '../../common/validation/schemas.js';
import { areaQuery, bannerBody } from './home.validation.js';

const parseAreaQuery = (query: unknown) => parse(areaQuery, query);

test('home area resolves province code, GPS point and falls back to nationwide', () => {
  assert.deepEqual(resolveArea({ provinceCode: '79' }), { code: '79', name: 'TP. Hồ Chí Minh' });
  assert.deepEqual(resolveArea({ point: { latitude: 10.7769, longitude: 106.7009 } }), { code: '79', name: 'TP. Hồ Chí Minh' });
  assert.deepEqual(resolveArea({ point: { latitude: 0, longitude: 0 } }), NATIONWIDE_AREA);
  assert.deepEqual(resolveArea({}), NATIONWIDE_AREA);
  assert.throws(() => resolveArea({ provinceCode: 'xx' }), AppError);
});

test('home area query requires both coordinates', () => {
  assert.deepEqual(parseAreaQuery({}), { point: undefined, provinceCode: undefined });
  assert.throws(() => parseAreaQuery({ latitude: '10.7' }), AppError);
  assert.throws(() => parseAreaQuery({ latitude: '200', longitude: '10' }), AppError);
});

test('banner body validates fields and rejects unknown keys', () => {
  const create = (body: unknown) => parse(bannerBody(false), body);
  const update = (body: unknown) => parse(bannerBody(true), body);
  assert.deepEqual(create({ title: ' Sale ', route: '/trusted-shops', sortOrder: 2 }).data,
    { title: 'Sale', route: '/trusted-shops', sortOrder: 2 });
  assert.throws(() => create({}), AppError);
  assert.throws(() => create({ title: 'x', route: 'https://evil.example' }), AppError);
  assert.throws(() => create({ title: 'x', imageUrl: 'javascript:alert(1)' }), AppError);
  assert.throws(() => create({ title: 'x', startsAt: '2026-12-01', endsAt: '2026-11-01' }), AppError);
  assert.throws(() => create({ title: 'x', extra: 1 }), AppError);
  assert.throws(() => update({}), AppError);
  assert.deepEqual(update({ imageUrl: null }).data, { imageUrl: null });
});
