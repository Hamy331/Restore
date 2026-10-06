import assert from 'node:assert/strict';
import test from 'node:test';
import { ListingStatus, Prisma } from '@prisma/client';
import { canChangeListingStatus, createInput, draftInput, imageExtension, listingFilters, orderedImages, requireOwnedListing, updateOwnedListing } from './listing.route.js';
import { storeUsage } from '../stores/store.service.js';

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

test('listing images accept real supported bytes and cannot attach foreign URLs or duplicates', () => {
  assert.equal(imageExtension('image/jpeg', Buffer.from([0xff, 0xd8, 0xff, 0x00])), 'jpg');
  assert.throws(() => imageExtension('image/jpeg', Buffer.from('fake image')), { code: 'INVALID_IMAGE' });
  assert.throws(() => imageExtension('image/png', Buffer.alloc(5 * 1024 * 1024 + 1)), { code: 'INVALID_IMAGE' });
  const urls = ['/api/v1/listings/media/a.jpg', '/api/v1/listings/media/b.png'];
  assert.deepEqual(orderedImages([urls[1], urls[0]], urls), [urls[1], urls[0]]);
  assert.throws(() => orderedImages([urls[0], urls[0]], urls), { code: 'INVALID_IMAGES' });
  assert.throws(() => orderedImages(['https://example.com/foreign.jpg'], urls), { code: 'INVALID_IMAGES' });
});

test('listing filters validate range and normalize search values', () => {
  assert.deepEqual(listingFilters({ q: '  bàn gỗ ', categoryId: 'furniture', condition: 'USED_GOOD', minPrice: '100000', maxPrice: '200000' }), {
    q: 'bàn gỗ', categoryId: 'furniture', condition: 'USED_GOOD', minPrice: '100000', maxPrice: '200000',
  });
  assert.throws(() => listingFilters({ minPrice: '200', maxPrice: '100' }), { code: 'INVALID_QUERY' });
  assert.throws(() => listingFilters({ minPrice: '-1' }), { code: 'INVALID_QUERY' });
  assert.throws(() => listingFilters({ condition: 'FAKE' }), { code: 'INVALID_QUERY' });
});

test('draft accepts missing content but publication requires complete content', () => {
  const draft = draftInput({ title: '  Bàn gỗ ', price: '', categoryId: '' });
  assert.deepEqual(draft, {
    title: 'Bàn gỗ', description: '', price: '0', condition: 'USED_GOOD',
    categoryId: null, isNegotiable: true,
  });
  assert.throws(() => createInput(draft), { code: 'INVALID_LISTING' });
  assert.throws(() => draftInput({ price: '-5' }), { code: 'INVALID_DRAFT' });
  assert.throws(() => draftInput({ ownerId: 'someone-else' }), { code: 'INVALID_DRAFT' });
});

test('daily listing quota counts publication time, so drafts do not consume it', async () => {
  const where: unknown[] = [];
  const tx = {
    listing: { count: async (args: { where: unknown }) => { where.push(args.where); return 0; } },
    promotion: { count: async () => 0 },
  } as unknown as Prisma.TransactionClient;
  await storeUsage(tx, 'user-1', new Date('2026-10-07T12:00:00Z'));
  assert.deepEqual(where[0], { ownerId: 'user-1', publishedAt: { gte: new Date('2026-10-07T00:00:00Z') } });
});
