import assert from 'node:assert/strict';
import test from 'node:test';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { listMessages } from './chat.service.js';

test('catch-up scans forward across product contexts and advances by the last returned sequence', async t => {
  const thread = prisma.conversation.findFirst;
  const messages = prisma.message.findMany;
  t.after(() => { prisma.conversation.findFirst = thread; prisma.message.findMany = messages; });
  prisma.conversation.findFirst = (async () => ({ threadId: 'shop-thread' })) as never;
  prisma.message.findMany = (async (args: Prisma.MessageFindManyArgs) => {
    assert.deepEqual(args.where, { conversation: { OR: [{ id: 'shop-thread' }, { threadId: 'shop-thread' }] }, sequence: { gt: 12 } });
    assert.deepEqual(args.orderBy, { sequence: 'asc' });
    assert.equal(args.take, 3);
    return [{ sequence: 19 }, { sequence: 25 }, { sequence: 36 }];
  }) as never;
  const page = await listMessages('buyer', 'product-context', { after: '12', limit: '2' });
  assert.deepEqual(page, { items: [{ sequence: 19 }, { sequence: 25 }], hasMore: true, nextAfter: 25 });
  await assert.rejects(listMessages('buyer', 'product-context', { before: '90', after: '12' }), { code: 'INVALID_PAGINATION' });
});
