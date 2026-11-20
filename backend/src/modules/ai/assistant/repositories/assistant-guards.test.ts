import assert from 'node:assert/strict';
import { test } from 'node:test';
import { prisma } from '../../../../lib/prisma.js';
import { send } from '../services/assistant.service.js';
import type { AiProvider } from '../assistant.type.js';

// Exercise the real service/repository path with an isolated transaction adapter.
// These tests never connect to the configured application database.
test('rapid local replies across conversations are rate limited before any provider call', async t => {
  const turns: any[] = [];
  let usage: any = null;
  let quotaWrites = 0;
  const tx = {
    aiConversation: {
      upsert: async () => ({ userId: 'self', busyUntil: null }),
      update: async () => ({}), updateMany: async () => ({ count: 1 }),
    },
    aiTurn: {
      findUnique: async () => null,
      count: async ({ where }: any) => {
        assert.equal(where.conversation.userId, 'self');
        assert.ok(where.createdAt.gt instanceof Date);
        return turns.length;
      },
      create: async ({ data }: any) => { turns.push(data); return data; },
    },
    aiUsage: {
      findUnique: async () => usage,
      upsert: async ({ create, update }: any) => { quotaWrites++; usage = usage ? { ...usage, ...update } : create; },
    },
  };
  t.mock.method(prisma, '$transaction', async (work: any) => work(tx));
  // Prisma delegates are dynamic proxies; MockTracker cannot inspect their
  // virtual method descriptors, so restore this one method explicitly.
  const findMany = prisma.aiTurn.findMany;
  prisma.aiTurn.findMany = (async () => []) as typeof findMany;
  t.after(() => { prisma.aiTurn.findMany = findMany; });
  const provider: AiProvider = { embeddingModel: 'test', embed: async () => assert.fail('embedding called'), generate: async () => assert.fail('provider called') };
  for (let i = 0; i < 5; i++) await send('self', `conversation-${i}`, `request-${i}`, 'asdfgh', provider);
  await assert.rejects(send('self', 'conversation-6', 'request-6', 'asdfgh', provider), { code: 'AI_RATE_LIMIT' });
  assert.equal(turns.length, 5); assert.equal(quotaWrites, 5);
});

test('foreign conversations are rejected before model execution', async t => {
  t.mock.method(prisma, '$transaction', async (work: any) => work({ aiConversation: { upsert: async () => ({ userId: 'someone-else' }) } }));
  await assert.rejects(send('self', 'foreign', 'request', 'asdfgh'), { code: 'AI_CONVERSATION_NOT_FOUND' });
});
