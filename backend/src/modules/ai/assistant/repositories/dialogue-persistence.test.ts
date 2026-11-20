import assert from 'node:assert/strict';
import { test } from 'node:test';
import { prisma } from '../../../../lib/prisma.js';
import { send } from '../services/assistant.service.js';
import { ToolSession } from '../services/tools.service.js';
import { emptyState } from '../services/conversation-state.js';
import type { AiProvider } from '../assistant.type.js';

test('persisted shopping state survives reopening; retry is idempotent and failed tools do not change it', async t => {
  let state: any = { ...emptyState(), intent: 'shopping', slots: { query: 'ghế', categoryId: 'furniture' }, pending: 'budget' };
  let turns: any[] = [];
  let failWrite = false;
  const tx = {
    aiConversation: {
      upsert: async () => ({ userId: 'self', state, busyUntil: null }),
      update: async () => ({}),
      updateMany: async ({ data }: any) => { if (data.state) state = data.state; return { count: 1 }; },
    },
    aiTurn: {
      findUnique: async ({ where }: any) => turns.find(turn => turn.requestId === where.conversationId_requestId.requestId) ?? null,
      count: async () => 0,
      create: async ({ data }: any) => { if (failWrite) throw Error('commit failed'); turns.push(data); return data; },
    },
    aiUsage: { findUnique: async () => null, upsert: async () => ({}) },
  };
  t.mock.method(prisma, '$transaction', async (work: any) => {
    const before = structuredClone(state), beforeTurns = structuredClone(turns);
    try { return await work(tx); } catch (e) { state = before; turns = beforeTurns; throw e; }
  });
  const findMany = prisma.aiTurn.findMany;
  prisma.aiTurn.findMany = (async () => [...turns].reverse()) as typeof findMany;
  t.after(() => { prisma.aiTurn.findMany = findMany; });
  const calls: any[] = [];
  let failTool = false;
  t.mock.method(ToolSession.prototype, 'execute', async function(this: ToolSession, tool: string, args: any) {
    calls.push({ tool, args });
    if (failTool) throw Error('unavailable');
    const items = [{ id: 'chair-a', title: 'Ghế gỗ', price: tool === 'listing_details' ? '900000' : '800000', areaLabel: 'Hà Nội' }];
    this.reply.listings = items;
    return { items };
  });
  const provider: AiProvider = { embeddingModel: 'test', embed: async () => assert.fail(), generate: async () => assert.fail() };
  const first = await send('self', 'chat', 'r1', '1 triệu', provider);
  assert.equal(state.slots.maxPrice, '1000000');
  assert.deepEqual(state.results, ['chair-a']);
  assert.deepEqual(await send('self', 'chat', 'r1', '1 triệu', provider), first);
  assert.equal(calls.length, 1);
  await send('self', 'chat', 'r2', 'cái đầu', provider);
  assert.deepEqual(state.selected, ['chair-a']);
  await send('self', 'chat', 'r3', 'rẻ hơn', provider);
  assert.equal(calls.at(-1).args.maxPrice, '899999'); // Fresh details, not the prior card price.
  assert.equal(state.slots.maxPrice, '899999');
  const before = structuredClone(state);
  failTool = true;
  await assert.rejects(send('self', 'chat', 'r4', 'tăng lên 2 triệu', provider));
  assert.deepEqual(state, before);
  failTool = false; failWrite = true;
  await assert.rejects(send('self', 'chat', 'r5', '2 triệu', provider));
  assert.deepEqual(state, before);
  await assert.rejects(send('self', 'chat', 'r6', 'Bắt đầu lại', provider, { signal: AbortSignal.abort() }));
  assert.deepEqual(state, before);
  assert.equal(turns.length, 3);
});
