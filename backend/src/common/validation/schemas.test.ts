import assert from 'node:assert/strict';
import test from 'node:test';
import { z } from 'zod';
import { AppError } from '../errors/app-error.js';
import { coordinates, idParam, int, oneOf, optionalBool, optionalIsoDate, optionalStr, pageQuery, parse, str, strictBody } from './schemas.js';

/** Chạy hàm, trả về { ok } hoặc { error: { statusCode, code, message, field } } của AppError */
function outcome(run: () => unknown) {
  try {
    return { ok: run() };
  } catch (error) {
    assert.ok(error instanceof AppError, `expected AppError, got ${String(error)}`);
    return { error: { statusCode: error.statusCode, code: error.code, message: error.message, field: error.field } };
  }
}

/**
 * Kết quả mong đợi, ghi lại từ các parser cũ (common/validation/parsers.ts, common/http/pagination.ts)
 * trước khi xóa chúng ở C22. Schema zod phải cho đúng giá trị và đúng lỗi như vậy.
 */
const EXPECTED: Record<string, [unknown, unknown][]> = {
  pageQuery: [
    [{  }, { "ok": { "page": 1, "limit": 10, "skip": 0 } }],
    [{ "page": "2" }, { "ok": { "page": 2, "limit": 10, "skip": 10 } }],
    [{ "page": "3", "limit": "5" }, { "ok": { "page": 3, "limit": 5, "skip": 10 } }],
    [{ "pageSize": "7" }, { "ok": { "page": 1, "limit": 7, "skip": 0 } }],
    [{ "limit": "4", "pageSize": "9" }, { "ok": { "page": 1, "limit": 4, "skip": 0 } }],
    [{ "page": "0" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "page phải là số nguyên từ 1 đến 100000.", "field": "page" } }],
    [{ "page": "abc" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "page phải là số nguyên từ 1 đến 100000.", "field": "page" } }],
    [{ "page": "1.5" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "page phải là số nguyên từ 1 đến 100000.", "field": "page" } }],
    [{ "limit": "51" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "limit phải là số nguyên từ 1 đến 50.", "field": "limit" } }],
    [{ "limit": "0" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "limit phải là số nguyên từ 1 đến 50.", "field": "limit" } }],
    [{ "pageSize": "-1" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "limit phải là số nguyên từ 1 đến 50.", "field": "limit" } }],
    [{ "page": "", "limit": "" }, { "ok": { "page": 1, "limit": 10, "skip": 0 } }],
  ],
  pageQuery100: [
    [{ "limit": "100" }, { "ok": { "page": 1, "limit": 100, "skip": 0 } }],
    [{ "limit": "101" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "limit phải là số nguyên từ 1 đến 100.", "field": "limit" } }],
    [{  }, { "ok": { "page": 1, "limit": 20, "skip": 0 } }],
  ],
  coordinates: [
    [{  }, { "ok": undefined }],
    [{ "latitude": "10.7", "longitude": "106.7" }, { "ok": { "latitude": 10.7, "longitude": 106.7 } }],
    [{ "latitude": "10.7" }, { "error": { "statusCode": 400, "code": "INVALID_LOCATION", "message": "Cần đủ latitude và longitude hợp lệ.", "field": "location" } }],
    [{ "longitude": "1" }, { "error": { "statusCode": 400, "code": "INVALID_LOCATION", "message": "Cần đủ latitude và longitude hợp lệ.", "field": "location" } }],
    [{ "latitude": "200", "longitude": "10" }, { "error": { "statusCode": 400, "code": "INVALID_LOCATION", "message": "Cần đủ latitude và longitude hợp lệ.", "field": "location" } }],
    [{ "latitude": "x", "longitude": "1" }, { "error": { "statusCode": 400, "code": "INVALID_LOCATION", "message": "Cần đủ latitude và longitude hợp lệ.", "field": "location" } }],
    [{ "latitude": "", "longitude": "" }, { "ok": undefined }],
    [{ "latitude": -90, "longitude": 180 }, { "ok": { "latitude": -90, "longitude": 180 } }],
  ],
  idParam: [
    [{ "id": "banner-1" }, { "ok": { "id": "banner-1" } }],
    [{ "id": "  x  " }, { "ok": { "id": "x" } }],
    [{ "id": "" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "id phải là chuỗi từ 1 đến 64 ký tự.", "field": "id" } }],
    [{  }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "id phải là chuỗi từ 1 đến 64 ký tự.", "field": "id" } }],
    [{ "id": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "id phải là chuỗi từ 1 đến 64 ký tự.", "field": "id" } }],
    [{ "id": 5 }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "id phải là chuỗi từ 1 đến 64 ký tự.", "field": "id" } }],
  ],
  str: [
    ["abc", { "ok": "abc" }],
    ["  t  ", { "ok": "t" }],
    ["", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "title phải là chuỗi từ 1 đến 120 ký tự.", "field": "title" } }],
    [1, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "title phải là chuỗi từ 1 đến 120 ký tự.", "field": "title" } }],
    ["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "title phải là chuỗi từ 1 đến 120 ký tự.", "field": "title" } }],
  ],
  optionalStr: [
    [undefined, { "ok": undefined }],
    [null, { "ok": undefined }],
    ["", { "ok": undefined }],
    [" a ", { "ok": "a" }],
    [3, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "q phải là chuỗi từ 1 đến 10 ký tự.", "field": "q" } }],
  ],
  int: [
    [undefined, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "Thiếu sortOrder.", "field": "sortOrder" } }],
    ["", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "Thiếu sortOrder.", "field": "sortOrder" } }],
    ["5", { "ok": 5 }],
    [5, { "ok": 5 }],
    ["-1", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "sortOrder phải là số nguyên từ 0 đến 1000.", "field": "sortOrder" } }],
    ["1001", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "sortOrder phải là số nguyên từ 0 đến 1000.", "field": "sortOrder" } }],
    ["x", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "sortOrder phải là số nguyên từ 0 đến 1000.", "field": "sortOrder" } }],
  ],
  oneOf: [
    [undefined, { "ok": "newest" }],
    ["", { "ok": "newest" }],
    ["nearby", { "ok": "nearby" }],
    ["other", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "filter chỉ nhận: newest, nearby, exchange.", "field": "filter" } }],
    [1, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "filter chỉ nhận: newest, nearby, exchange.", "field": "filter" } }],
  ],
  optionalBool: [
    [undefined, { "ok": undefined }],
    [null, { "ok": undefined }],
    ["", { "ok": undefined }],
    [true, { "ok": true }],
    ["false", { "ok": false }],
    ["yes", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "active chỉ nhận true hoặc false.", "field": "active" } }],
  ],
  optionalIsoDate: [
    [undefined, { "ok": undefined }],
    [null, { "ok": null }],
    ["", { "ok": null }],
    ["2026-10-01T00:00:00.000Z", { "ok": new Date('2026-10-01T00:00:00.000Z') }],
    ["nope", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "startsAt phải là ngày giờ ISO 8601.", "field": "startsAt" } }],
    [5, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "startsAt phải là ngày giờ ISO 8601.", "field": "startsAt" } }],
  ],
  strictBody: [
    [{ "title": "a" }, { "ok": { "title": "a" } }],
    [{  }, { "ok": {  } }],
    [{ "title": "a", "extra": 1 }, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "Trường extra không được hỗ trợ.", "field": "extra" } }],
    [null, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "Body phải là một object JSON.", "field": "body" } }],
    [[], { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "Body phải là một object JSON.", "field": "body" } }],
    ["text", { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "Body phải là một object JSON.", "field": "body" } }],
    [3, { "error": { "statusCode": 400, "code": "INVALID_INPUT", "message": "Body phải là một object JSON.", "field": "body" } }],
  ],
};

function check(cases: [unknown, unknown][], schema: z.ZodType) {
  for (const [input, expected] of cases) {
    assert.deepEqual(outcome(() => parse(schema, input)), expected, `input: ${JSON.stringify(input)}`);
  }
}

/** Bọc schema một trường thành schema nhận đúng giá trị đó */
const field = (schema: z.ZodType) => z.object({ v: schema }).transform(({ v }) => v);
const wrap = (cases: [unknown, unknown][]) => cases.map(([input, expected]) => [{ v: input }, expected] as [unknown, unknown]);

test('pageQuery: page, limit, pageSize alias, errors', () => {
  check(EXPECTED.pageQuery, pageQuery());
  check(EXPECTED.pageQuery100, pageQuery({ defaultLimit: 20, maxLimit: 100 }));
});

test('coordinates: optional pair, both or neither', () => check(EXPECTED.coordinates, coordinates));

test('idParam requires a 1–64 char id', () => check(EXPECTED.idParam, idParam()));

test('field helpers', () => {
  check(wrap(EXPECTED.str), field(str('title', { max: 120 })));
  check(wrap(EXPECTED.optionalStr), field(optionalStr('q', { max: 10 })));
  check(wrap(EXPECTED.int), field(int('sortOrder', { min: 0, max: 1000 })));
  check(wrap(EXPECTED.oneOf), field(oneOf('filter', ['newest', 'nearby', 'exchange'] as const, 'newest')));
  check(wrap(EXPECTED.optionalBool), field(optionalBool('active')));
  check(wrap(EXPECTED.optionalIsoDate), field(optionalIsoDate('startsAt')));
});

test('strictBody rejects non-objects and unknown keys', () => {
  check(EXPECTED.strictBody, strictBody({ title: z.unknown().optional(), active: z.unknown().optional() }));
});
