import assert from 'node:assert/strict';
import test from 'node:test';
import express from 'express';
import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import router from './listing.route.js';
import { errorHandler } from '../../middlewares/error.middleware.js';

test('detail refresh preserves views and returns public seller metadata', async () => {
  const original = { find: prisma.listing.findFirst, count: prisma.listing.count, raw: prisma.$queryRaw };
  let views = 0;
  prisma.listing.findFirst = (async () => ({ id: 'item', ownerId: 'seller', price: new Prisma.Decimal(100),
    location: null, category: null, owner: {id:'seller', fullName:'Seller'}, viewCount: views })) as unknown as typeof prisma.listing.findFirst;
  prisma.listing.count = (async () => 3) as typeof prisma.listing.count;
  prisma.$queryRaw = (async (_sql: unknown, skip: boolean) => [{viewCount: skip ? views : ++views}]) as typeof prisma.$queryRaw;
  const app = express();
  app.use(router);
  app.use(errorHandler);
  const server = app.listen(0, '127.0.0.1');
  try {
    await new Promise<void>(resolve => server.once('listening', resolve));
    const port = (server.address() as {port:number}).port;
    const read = async (query = '') => (await fetch(`http://127.0.0.1:${port}/item${query}`)).json() as Promise<{data: {viewCount:number; isOwner:boolean; isFavorite:boolean; sellerActiveListings:number}}>;
    assert.equal((await read()).data.viewCount, 1);
    const refresh = (await read('?countView=false')).data;
    assert.equal(refresh.viewCount, 1);
    assert.equal(refresh.isOwner, false);
    assert.equal(refresh.isFavorite, false);
    assert.equal(refresh.sellerActiveListings, 3);
    assert.equal((await fetch(`http://127.0.0.1:${port}/item?countView=invalid`)).status, 400);
    assert.equal(views, 1);
  } finally {
    prisma.listing.findFirst = original.find;
    prisma.listing.count = original.count;
    prisma.$queryRaw = original.raw;
    server.closeAllConnections();
    await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  }
});
