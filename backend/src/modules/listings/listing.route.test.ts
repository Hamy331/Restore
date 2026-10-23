import assert from 'node:assert/strict';
import test from 'node:test';
import { ListingStatus, Prisma } from '@prisma/client';
import { canChangeListingStatus, createInput, draftInput, imageExtension, listingFilters, orderedImages, requireOwnedListing, updateOwnedListing } from './listing.route.js';
import { storeUsage } from '../stores/store.service.js';
import { catalog, publicLocation } from '../catalog/catalog.js';
import { validateAttributes } from './listing-input.js';
const province=catalog.provinces[0]!;
const ward=catalog.wards[province.code]![0]!;
const location={provinceCode:province.code,wardCode:ward.code,streetAddress:'Nhà riêng',...ward.center,geoSource:'device'};

test('listing creation accepts supported fields and rejects invalid or silently discarded data', () => {
  const valid = {
    title: 'Bàn gỗ sồi',
    description: 'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
    price: '1200000',
    condition: 'USED_GOOD',
    categoryId: 'furniture',
    isNegotiable: true,
    location,
  };
  const result=createInput(valid);
  assert.equal(result.title,valid.title);
  assert.equal(result.price,valid.price);
  assert.equal(result.allowSale,true);
  assert.equal(result.allowExchange,false);
  assert.equal((result.location as {streetAddress:string}).streetAddress,'Nhà riêng');
  assert.equal((publicLocation(result.location) as unknown as {streetAddress?:string}).streetAddress,undefined);
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
  assert.equal(draft.title,'Bàn gỗ');
  assert.equal(draft.description,'');
  assert.equal(draft.price,'0');
  assert.equal(draft.condition,null);
  assert.equal(draft.categoryId,null);
  assert.equal(draft.location,Prisma.DbNull);
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

test('category attributes and GPS enforce supported values',()=>{
  const metadata={attributes:[{key:'year',type:'number',required:true,min:2000,max:2030},{key:'brand',type:'select',options:[{value:'apple'}]}]};
  validateAttributes({year:2026,brand:'apple'},metadata,true);
  assert.throws(()=>validateAttributes({},metadata,true),{code:'INVALID_ATTRIBUTES'});
  assert.throws(()=>validateAttributes({year:'2026'},metadata,true),{code:'INVALID_ATTRIBUTES'});
  assert.throws(()=>validateAttributes({year:1999},metadata,true),{code:'INVALID_ATTRIBUTES'});
  assert.throws(()=>validateAttributes({year:2026,brand:'fake'},metadata,true),{code:'INVALID_ATTRIBUTES'});
  assert.throws(()=>validateAttributes({ownerId:'someone'},metadata,false),{code:'INVALID_ATTRIBUTES'});
  assert.throws(()=>listingFilters({latitude:'91',longitude:'1'}),{code:'INVALID_LOCATION'});
  assert.throws(()=>listingFilters({latitude:'1'}),{code:'INVALID_QUERY'});
});

test('new UI filters accept multiple conditions, trade type and price ordering', () => {
  const filters = listingFilters({condition: 'USED_GOOD,NEW', deal: 'exchange', sort: 'price_asc'});
  assert.deepEqual(filters.conditions, ['USED_GOOD','NEW']);
  assert.equal(filters.condition, null);
  assert.equal(filters.deal, 'exchange');
  assert.equal(filters.sort, 'price_asc');
  assert.throws(() => listingFilters({deal:'unknown'}), {code:'INVALID_QUERY'});
  assert.throws(() => listingFilters({sort:'price; DROP TABLE'}), {code:'INVALID_QUERY'});
});
