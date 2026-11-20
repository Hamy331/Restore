import assert from 'node:assert/strict';
import test from 'node:test';
import { AppError } from '../../common/errors/app-error.js';
import { parse } from '../../common/validation/schemas.js';
import { toNotificationDto } from './notification.dto.js';
import { groupOf, typesOfGroup } from './notification.type.js';
import { listQuery } from './notification.validator.js';

test('notification types map to filter groups, unknown types fall back to system', () => {
  assert.equal(groupOf('LISTING_APPROVED'), 'listing');
  assert.equal(groupOf('CREDIT_TOPUP_SUCCESS'), 'wallet');
  assert.equal(groupOf('WANTED_ALERT_MATCH'), 'activity');
  assert.equal(groupOf('SOMETHING_NEW'), 'system');
  assert.ok(typesOfGroup('listing').includes('LISTING_EDIT_REJECTED'));
  assert.ok(!typesOfGroup('wallet').includes('LISTING_APPROVED'));
});

test('list query parses paging, group and unread', () => {
  assert.deepEqual(parse(listQuery, {}), { page: 1, limit: 20, skip: 0, group: null, unread: false });
  assert.deepEqual(parse(listQuery, { page: '2', limit: '10', group: 'wallet', unread: 'true' }),
    { page: 2, limit: 10, skip: 10, group: 'wallet', unread: true });
  assert.throws(() => parse(listQuery, { group: 'nope' }), (error) => (error as AppError).field === 'group');
});

test('dto exposes read state and group', () => {
  const createdAt = new Date('2026-11-18T10:00:00Z');
  const dto = toNotificationDto({ id: 'n1', type: 'LISTING_REJECTED', title: 't', body: 'b', data: { listingId: 'l1' },
    imageUrl: null, link: '/listings/l1', readAt: null, createdAt });
  assert.equal(dto.group, 'listing');
  assert.equal(dto.isRead, false);
  assert.deepEqual(dto.data, { listingId: 'l1' });
});
