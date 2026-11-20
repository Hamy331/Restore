import assert from 'node:assert/strict';
import test from 'node:test';
import { adminReportQuery } from '../content.validator.js';
import { reportGroupOrder, reportSqlWhere, reportWhere } from './report-query.js';

test('waiting bounds are inclusive and calculated from a shared server timestamp', () => {
  const now = new Date('2026-11-18T12:00:00Z');
  const query = adminReportQuery.parse({ status: 'OPEN', minWaitHours: '1.5', maxWaitHours: '9', reasonCode: 'A_NEW_REASON', targetType: 'LISTING' });
  const where = reportWhere(query, now);
  assert.deepEqual(where, { status: 'OPEN', targetType: 'LISTING', reasonCode: 'A_NEW_REASON',
    createdAt: { lte: new Date('2026-11-18T10:30:00Z'), gte: new Date('2026-11-18T03:00:00Z') } });
  const sql = reportSqlWhere(query, now);
  assert.ok(sql.values.includes('A_NEW_REASON'));
  assert.deepEqual(sql.values.filter(v => v instanceof Date), Object.values(where.createdAt!));
});

test('invalid age ranges, pagination and sort cannot reach group queries', () => {
  for (const raw of [
    { minWaitHours: '1' }, { status: 'RESOLVED', minWaitHours: '1' },
    { status: 'OPEN', minWaitHours: '-1' }, { status: 'OPEN', minWaitHours: 'NaN' },
    { status: 'OPEN', minWaitHours: '3', maxWaitHours: '2' },
    { sort: 'DROP TABLE' }, { limit: '101' }, { page: '0' },
    { uncategorized: 'true', reasonCode: 'A' }, { asOf: 'not-a-date' },
    { asOf: new Date(Date.now() + 60_000).toISOString() },
  ]) assert.throws(() => adminReportQuery.parse(raw));
});

test('drill-down shares the group cutoff and does not include later arrivals', () => {
  const asOf = new Date('2026-01-01T00:00:00Z');
  const query = adminReportQuery.parse({ status: 'OPEN', asOf: asOf.toISOString() });
  assert.deepEqual(reportWhere(query, query.asOf!).createdAt, { lte: asOf });
});

test('raw group query uses bound values and deterministic order, including old uncategorized reports', () => {
  const attack = "x' OR TRUE --";
  const query = adminReportQuery.parse({ reasonCode: attack });
  const sql = reportSqlWhere(query, new Date());
  assert.ok(sql.values.includes(attack));
  assert.ok(!sql.strings.join('').includes(attack));
  const legacy = reportWhere(adminReportQuery.parse({ uncategorized: 'true' }), new Date());
  assert.equal(legacy.reasonCode, null);
  for (const sort of ['oldest', 'newest', 'most_reports'] as const) {
    const order = reportGroupOrder(sort).strings.join('');
    assert.match(order, /targetType/); assert.match(order, /targetId/);
  }
});

