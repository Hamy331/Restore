import assert from 'node:assert/strict';
import test from 'node:test';
import { z } from 'zod';
import { AppError } from '../errors/app-error.js';
import { parsePagination } from '../http/pagination.js';
import * as legacy from './parsers.js';
import { coordinates, idParam, int, oneOf, optionalBool, optionalIsoDate, optionalStr, pageQuery, parse, str, strictBody } from './schemas.js';

/** Chạy hàm, trả về kết quả hoặc { statusCode, code, message, field } của AppError */
function outcome(run: () => unknown) {
  try {
    return { ok: run() };
  } catch (error) {
    assert.ok(error instanceof AppError, `expected AppError, got ${String(error)}`);
    return { error: { statusCode: error.statusCode, code: error.code, message: error.message, field: error.field } };
  }
}

/** Schema mới phải cho đúng kết quả và đúng lỗi như parser cũ */
function sameAsLegacy(inputs: unknown[], legacyFn: (value: unknown) => unknown, schema: z.ZodType) {
  for (const input of inputs) {
    assert.deepEqual(outcome(() => parse(schema, input)), outcome(() => legacyFn(input)), `input: ${JSON.stringify(input)}`);
  }
}

test('pageQuery matches parsePagination (page, limit, pageSize alias, errors)', () => {
  const queries = [{}, { page: '2' }, { page: '3', limit: '5' }, { pageSize: '7' }, { limit: '4', pageSize: '9' },
    { page: '0' }, { page: 'abc' }, { page: '1.5' }, { limit: '51' }, { limit: '0' }, { pageSize: '-1' }, { page: '', limit: '' }];
  sameAsLegacy(queries, (q) => parsePagination(q as Record<string, unknown>), pageQuery());
  sameAsLegacy([{ limit: '100' }, { limit: '101' }, {}], (q) => parsePagination(q as Record<string, unknown>, { defaultLimit: 20, maxLimit: 100 }),
    pageQuery({ defaultLimit: 20, maxLimit: 100 }));
});

test('coordinates match optionalCoordinates', () => {
  const queries = [{}, { latitude: '10.7', longitude: '106.7' }, { latitude: '10.7' }, { longitude: '1' },
    { latitude: '200', longitude: '10' }, { latitude: 'x', longitude: '1' }, { latitude: '', longitude: '' }, { latitude: -90, longitude: 180 }];
  sameAsLegacy(queries, (q) => { const v = q as Record<string, unknown>; return legacy.optionalCoordinates(v.latitude, v.longitude); }, coordinates);
});

test('idParam requires a 1–64 char id', () => {
  sameAsLegacy([{ id: 'banner-1' }, { id: '  x  ' }, { id: '' }, {}, { id: 'a'.repeat(65) }, { id: 5 }],
    (p) => ({ id: legacy.requiredString((p as Record<string, unknown>).id, 'id', { max: 64 }) }), idParam());
});

test('field helpers match parsers.ts', () => {
  sameAsLegacy(['abc', '  t  ', '', 1, 'x'.repeat(121)], (v) => legacy.requiredString(v, 'title', { max: 120 }), str('title', { max: 120 }));
  sameAsLegacy([undefined, null, '', ' a ', 3], (v) => legacy.optionalString(v, 'q', { max: 10 }), optionalStr('q', { max: 10 }));
  sameAsLegacy([undefined, '', '5', 5, '-1', '1001', 'x'], (v) => legacy.integerInRange(v, 'sortOrder', { min: 0, max: 1000 }),
    int('sortOrder', { min: 0, max: 1000 }));
  const filters = ['newest', 'nearby', 'exchange'] as const;
  sameAsLegacy([undefined, '', 'nearby', 'other', 1], (v) => legacy.oneOf(v, 'filter', filters, 'newest'), oneOf('filter', filters, 'newest'));
  sameAsLegacy([undefined, null, '', true, 'false', 'yes'], (v) => legacy.optionalBoolean(v, 'active'), optionalBool('active'));
  sameAsLegacy([undefined, null, '', '2026-10-01T00:00:00.000Z', 'nope', 5], (v) => legacy.optionalDate(v, 'startsAt'), optionalIsoDate('startsAt'));
});

test('strictBody rejects non-objects and unknown keys like jsonObject', () => {
  const schema = strictBody({ title: z.unknown().optional(), active: z.unknown().optional() });
  sameAsLegacy([{ title: 'a' }, {}, { title: 'a', extra: 1 }],
    (v) => legacy.jsonObject(v, ['title', 'active']), schema);
  for (const value of [null, [], 'text', 3]) {
    assert.deepEqual(outcome(() => parse(schema, value)).error,
      { statusCode: 400, code: 'INVALID_INPUT', message: 'Body phải là một object JSON.', field: 'body' });
  }
});
