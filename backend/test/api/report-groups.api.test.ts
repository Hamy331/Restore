import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx, expect } = useApi('report-groups');

test('report groups authorize, filter before pagination and keep target types separate', async () => {
  const { api, tokens } = ctx;
  expect('guest groups denied', await api.get('/admin/report-groups'));
  expect('buyer groups denied', await api.get('/admin/report-groups', { token: tokens.buyer }));
  const { prisma } = await import('../../src/lib/prisma.js');
  const now = Date.now();
  const row = (id: string, targetId: string, hours: number, reasonCode: string | null, status: 'OPEN' | 'RESOLVED' = 'OPEN', targetType = 'LISTING') => ({
    id, targetId, targetType, reporterId: id + '-reporter', status, reasonCode,
    reason: reasonCode ?? 'Legacy free text', evidence: 'Fixture details', createdAt: new Date(now - hours * 3_600_000),
  });
  await prisma.violationReport.createMany({ data: [
    row('group-a', 'listing-1', 48, 'REASON_A'), row('group-b', 'listing-1', 2, 'REASON_B'),
    row('group-c', 'listing-2', 12, 'REASON_A'), row('group-d', 'listing-2', 1, null),
    row('group-e', 'listing-3', 100, 'REASON_A', 'RESOLVED'),
    row('group-f', 'listing-1', 72, 'REASON_A', 'OPEN', 'USER'),
  ] });
  const read = async (query: string) => {
    const result = await api.get('/admin/report-groups?' + query, { token: tokens.admin });
    assert.equal(result.status, 200);
    return result.body.data;
  };
  const first = await read('status=OPEN&targetType=LISTING&limit=1');
  assert.equal(first.total, 2); assert.equal(first.reportCount, 4);
  assert.equal(first.items.length, 1); assert.equal(first.items[0].targetId, 'listing-1');
  assert.equal(first.items[0].reportCount, 2); assert.equal(first.items[0].reasons.length, 2);
  assert.equal(first.items[0].listing.title, 'Bàn gỗ sồi thật');
  const second = await read('status=OPEN&targetType=LISTING&limit=1&page=2');
  assert.equal(second.items[0].targetId, 'listing-2'); assert.equal(second.items[0].reportCount, 2);
  const emptyPage = await read('status=OPEN&targetType=LISTING&limit=1&page=99');
  assert.equal(emptyPage.total, 2); assert.deepEqual(emptyPage.items, []);
  const filtered = await read('status=OPEN&targetType=LISTING&reasonCode=REASON_A');
  assert.equal(filtered.total, 2); assert.equal(filtered.reportCount, 2);
  assert.ok(filtered.items.every((item: { reportCount: number }) => item.reportCount === 1));
  const waiting = await read('status=OPEN&minWaitHours=24&maxWaitHours=60');
  assert.equal(waiting.total, 1); assert.equal(waiting.items[0].targetId, 'listing-1');
  assert.equal(waiting.items[0].reportCount, 1);
  const legacy = await read('status=OPEN&uncategorized=true');
  assert.equal(legacy.total, 1); assert.equal(legacy.items[0].targetId, 'listing-2');
  const allTypes = await read('status=OPEN');
  assert.equal(allTypes.total, 3);
  const userGroup = allTypes.items.find((item: { targetType: string }) => item.targetType === 'USER');
  assert.equal(userGroup.listing, null);
  const detail = await api.get('/admin/reports?status=OPEN&targetType=LISTING&targetId=listing-1&reasonCode=REASON_A', { token: tokens.admin });
  assert.equal(detail.body.data.total, 1); assert.equal(detail.body.data.items[0].id, 'group-a');
  const invalid = await api.get('/admin/report-groups?status=RESOLVED&minWaitHours=1', { token: tokens.admin });
  assert.equal(invalid.status, 400);
});

test('the listing form and admin filters read the same eight report reasons', async () => {
  const { api, tokens } = ctx;
  const publicList = await api.get('/content/reports/reasons', { token: tokens.buyer });
  const adminList = await api.get('/admin/report-reasons', { token: tokens.admin });
  assert.equal(publicList.status, 200); assert.equal(adminList.status, 200);
  assert.equal(publicList.body.data.items.length, 8);
  assert.deepEqual(publicList.body.data.items.map((item: { code: string }) => item.code),
    adminList.body.data.items.map((item: { code: string }) => item.code));
  const denied = await api.get('/admin/report-reasons', { token: tokens.buyer });
  assert.equal(denied.status, 403);
});
