import assert from 'node:assert/strict';
import test from 'node:test';
import { ListingStatus, Prisma } from '@prisma/client';
import { canChangeListingStatus, createInput, requireOwnedListing, updateOwnedListing } from './listing.route.js';

test('listing creation accepts supported fields and rejects invalid or silently discarded data', () => {
  const valid = {
    title: 'Bàn gỗ sồi',
    description: 'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
    price: '1200000',
    condition: 'USED_GOOD',
    categoryId: 'furniture',
    isNegotiable: true,
  };
  assert.deepEqual(createInput(valid), valid);
  assert.throws(() => createInput({ ...valid, price: '1.200.000' }), { code: 'INVALID_LISTING', field: 'price' });
  assert.throws(() => createInput({ ...valid, images: ['https://example.com/a.jpg'] }), { code: 'INVALID_LISTING' });
  assert.throws(() => createInput({ ...valid, condition: 'BROKEN' }), { code: 'INVALID_LISTING', field: 'condition' });
});

test('owner lookup and update always include the authenticated owner ID', async () => {
  const calls: unknown[] = [];
  const tx = { listing: {
    findFirst: async (args: unknown) => { calls.push(args); return null; },
    updateMany: async (args: unknown) => { calls.push(args); return { count: 0 }; },
  } } as unknown as Prisma.TransactionClient;
  await assert.rejects(requireOwnedListing(tx, 'listing-1', 'user-1'), { code: 'LISTING_NOT_FOUND' });
  await assert.rejects(updateOwnedListing(tx, 'listing-1', 'user-1', ListingStatus.AVAILABLE,
    { status: ListingStatus.HIDDEN }), { code: 'LISTING_CHANGED' });
  assert.deepEqual(calls, [
    { where: { id: 'listing-1', ownerId: 'user-1' } },
    { where: { id: 'listing-1', ownerId: 'user-1', status: ListingStatus.AVAILABLE },
      data: { status: ListingStatus.HIDDEN } },
  ]);
});

test('sold listings cannot be reopened, and hiding follows allowed transitions', () => {
  assert.equal(canChangeListingStatus(ListingStatus.AVAILABLE, ListingStatus.HIDDEN), true);
  assert.equal(canChangeListingStatus(ListingStatus.HIDDEN, ListingStatus.AVAILABLE), true);
  assert.equal(canChangeListingStatus(ListingStatus.HIDDEN, ListingStatus.SOLD), true);
  assert.equal(canChangeListingStatus(ListingStatus.SOLD, ListingStatus.AVAILABLE), false);
  assert.equal(canChangeListingStatus(ListingStatus.AVAILABLE, ListingStatus.AVAILABLE), false);
});
