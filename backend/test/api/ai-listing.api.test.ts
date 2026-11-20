import './support/env.js';
import assert from 'node:assert/strict';
import { test, before, after } from 'node:test';
import { prisma } from '../../src/lib/prisma.js';
import { resetDatabase, seedFixtures } from './support/database.js';
import { MemoryVectorStore } from './support/vector-store.js';
import { syncListingIndex } from '../../src/modules/ai/assistant/services/listing-index.service.js';
import { searchListings } from '../../src/modules/ai/assistant/services/listing-search.service.js';
import { cleanupVectors } from '../../src/modules/ai/rag/services/cleanup.service.js';
import type { AiProvider } from '../../src/modules/ai/assistant/assistant.type.js';

before(async () => { resetDatabase(); await seedFixtures(); });
after(async () => { await prisma.$disconnect(); });
const provider: AiProvider = {
  embeddingModel: 'listing-test', embed: async () => [1, ...Array(767).fill(0)],
  generate: async () => ({ role: 'model', parts: [{ text: 'unused' }] }),
};
const signal = () => AbortSignal.timeout(10000);

test('listing hybrid candidates are revalidated against SQL price, brand, category and owner status', async () => {
  const store = new MemoryVectorStore();
  await prisma.listing.update({ where: { id: 'listing-1' }, data: { title: 'Samsung S23', price: 4000000, attributes: { brand: 'Samsung' } } });
  await prisma.listing.update({ where: { id: 'listing-2' }, data: { title: 'Samsung S24', price: 9000000, attributes: { brand: 'Samsung' } } });
  await prisma.listing.update({ where: { id: 'listing-3' }, data: { title: 'Apple iPhone', price: 3000000, attributes: { brand: 'Apple' } } });
  const first = await syncListingIndex(provider, store);
  assert.equal(first.indexed, 3);
  assert.equal((await syncListingIndex(provider, store)).indexed, 0);
  // The double intentionally ignores Qdrant filters: SQL must still enforce all of them.
  const input = { q: 'điện thoại chụp ảnh', brand: 'samsung', maxPrice: '5000000', categoryId: 'furniture' };
  assert.deepEqual((await searchListings(input, provider, signal(), store)).map((row) => row.id), ['listing-1']);
  const index = await prisma.aiListingIndex.findUniqueOrThrow({ where: { listingId: 'listing-1' } });
  await prisma.listing.update({ where: { id: 'listing-1' }, data: { viewCount: { increment: 1 } } });
  assert.equal((await prisma.aiListingIndex.findUniqueOrThrow({ where: { listingId: 'listing-1' } })).pointId, index.pointId);
  await prisma.listing.update({ where: { id: 'listing-1' }, data: { price: 7000000 } });
  assert.equal(await prisma.aiListingIndex.findUnique({ where: { listingId: 'listing-1' } }), null);
  assert.deepEqual(await searchListings(input, provider, signal(), store), []);
  await syncListingIndex(provider, store);
  await prisma.user.update({ where: { id: 'user-seller' }, data: { status: 'BANNED' } });
  assert.deepEqual(await searchListings({ q: 'phone' }, provider, signal(), store), []);
  await prisma.user.update({ where: { id: 'user-seller' }, data: { status: 'ACTIVE' } });
});

test('failed writes never publish and changed/hidden/deleted listings queue vector cleanup', async () => {
  const store = new MemoryVectorStore();
  await prisma.aiListingIndex.deleteMany();
  store.failUpsert = true;
  await assert.rejects(syncListingIndex(provider, store));
  assert.equal(await prisma.aiListingIndex.count(), 0);
  store.failUpsert = false;
  await syncListingIndex(provider, store);
  await prisma.listing.update({ where: { id: 'listing-1' }, data: { status: 'HIDDEN' } });
  assert.ok(!(await searchListings({ q: 'phone' }, provider, signal(), store)).some((row) => row.id === 'listing-1'));
  const point = await prisma.aiListingIndex.findUniqueOrThrow({ where: { listingId: 'listing-2' } });
  await prisma.listing.delete({ where: { id: 'listing-2' } });
  assert.ok(await prisma.aiVectorDeletion.findUnique({ where: { pointId_collection: { pointId: point.pointId, collection: store.collection } } }));
  await cleanupVectors(store);
  assert.equal(store.points.has(point.pointId), false);
});
