import { test } from 'node:test';
import assert from 'node:assert/strict';
import { prisma } from '../src/lib/prisma.js';
import { createMessage } from '../src/modules/chat/repositories/chat.repository.js';

test('only inquiries include a snapshot of the product linked to the chat', async t => {
  const listing = { id: 'phone', title: 'iPhone', images: ['/cover'], price: 500, allowSale: true };
  const tx = {
    $queryRaw:async()=>[],
    conversationMember:{findFirst:async()=>null,updateMany:async()=>({})},
    listing: {
      findFirst: async ({ where }: any) => {
        assert.equal(where.conversations.some.threadId, 'shared-chat');
        assert.equal(where.status, 'AVAILABLE');
        return where.conversations.some.id === 'phone-chat' ? listing : null;
      },
    },
    message: { create: async ({ data }: any) => data },
    conversation: { updateMany: async () => ({}) },
    user: { update: async () => ({}) },
  };
  t.mock.method(prisma, '$transaction', async (run: any) => run(tx));
  const inquiry = await createMessage('shared-chat', 'buyer', '1', 'Still available?', 'phone-chat');
  listing.price = 450;
  assert.deepEqual(inquiry.listingPreview, { id: 'phone', title: 'iPhone', price: '500', image: '/cover' });
  const reply = await createMessage('shared-chat', 'seller', '2', 'Yes');
  assert.equal(reply.listingPreview, undefined);
  await assert.rejects(createMessage('shared-chat', 'buyer', '3', 'Hello', 'other-chat'), { statusCode: 409 });
});
