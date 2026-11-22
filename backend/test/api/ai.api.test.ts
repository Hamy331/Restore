import './support/env.js';
import './support/email-outbox.js';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { before, beforeEach, after, test } from 'node:test';
import { PASSWORD, resetDatabase, seedFixtures } from './support/database.js';
import { ApiClient } from './support/api-client.js';
import { prisma } from '../../src/lib/prisma.js';
import { AppError } from '../../src/common/errors/app-error.js';
import { send } from '../../src/modules/ai/assistant/services/assistant.service.js';
import { ToolSession } from '../../src/modules/ai/assistant/services/tools.service.js';
import * as conversations from '../../src/modules/ai/assistant/repositories/assistant.repository.js';
import { indexDocument, retrieve } from '../../src/modules/ai/rag/services/rag.service.js';
import type { AiProvider, Content } from '../../src/modules/ai/assistant/assistant.type.js';
import { MemoryVectorStore } from './support/vector-store.js';
import { cleanupVectors } from '../../src/modules/ai/rag/services/cleanup.service.js';

let api: ApiClient;
let buyer: string, seller: string, admin: string;
before(async () => {
  resetDatabase(); await seedFixtures(); api = await ApiClient.start();
  const login = async (id: string) => (await api.post('/auth/login', { body: { email: `${id}@restore.test`, password: PASSWORD } })).body.data.accessToken as string;
  buyer = await login('user-buyer'); seller = await login('user-seller'); admin = await login('user-admin');
});
beforeEach(async () => {
  await prisma.aiConversation.deleteMany(); await prisma.aiUsage.deleteMany();
  await prisma.listing.deleteMany({ where: { ownerId: 'user-buyer', status: 'DRAFT' } });
  await prisma.knowledgeDocument.deleteMany({ where: { id: { startsWith: 'ai-test-' } } });
  await prisma.aiVectorDeletion.deleteMany();
});
after(async () => { await api?.stop(); });

class ScriptedProvider implements AiProvider {
  embeddingModel = 'test-embedding';
  inputs: Content[][] = [];
  constructor(private readonly outputs: Content[] = []) {}
  async generate(contents: Content[]) {
    this.inputs.push(structuredClone(contents));
    return this.outputs.shift() ?? { role: 'model' as const, parts: [{ text: 'Đã tra cứu dữ liệu.' }] };
  }
  async embed() { return [1, ...Array(767).fill(0)]; }
}
const call = (name: string, args: unknown): Content => ({ role: 'model', parts: [{ functionCall: { name, args } }] });
const draft = { title: 'Điện thoại Samsung', description: 'Điện thoại đã qua sử dụng, cần bổ sung ảnh thật.', price: '2000000' };

test('AI routes enforce authentication, role, strict body and disabled provider', async () => {
  const path = `/ai/assistant/conversations/${randomUUID()}/messages`;
  assert.equal((await api.post(path, { body: {} })).status, 401);
  assert.equal((await api.post(path, { token: admin, body: {} })).status, 403);
  assert.equal((await api.post(path, { token: buyer, body: { requestId: randomUUID(), message: 'x', userId: 'other' } })).status, 400);
  process.env.AI_ENABLED = 'false';
  // Câu chào được trả lời tại chỗ, không cần AI; câu tìm sản phẩm mới phải gọi nhà cung cấp
  const unavailable = await api.post(path, { token: buyer, body: { requestId: randomUUID(), message: 'Mình cần tìm xe đạp cũ' } });
  assert.equal(unavailable.status, 503);
  assert.equal(unavailable.body.code, 'AI_NOT_CONFIGURED');
  assert.equal((await api.post('/ai/rag/documents/policy/index', { token: buyer, body: {} })).status, 403);
});

test('completed request replay does not call provider or spend quota; follow-up includes real prior context', async () => {
  const id = randomUUID(), requestId = randomUUID();
  const provider = new ScriptedProvider([call('search_listings', { q: '' })]);
  const first = await send('user-buyer', id, requestId, 'Tìm bàn', provider);
  assert.ok(first.listings.length);
  const calls = provider.inputs.length;
  assert.deepEqual(await send('user-buyer', id, requestId, 'Tìm bàn', provider), first);
  assert.equal(provider.inputs.length, calls);
  await assert.rejects(send('user-buyer', id, requestId, 'changed', provider), { code: 'AI_REQUEST_CHANGED' });
  await send('user-buyer', id, randomUUID(), 'rẻ hơn chút', provider);
  assert.ok(JSON.stringify(provider.inputs.at(-1)).includes('Tìm bàn'));
  assert.equal((await prisma.aiUsage.findUniqueOrThrow({ where: { userId: 'user-buyer' } })).windowCount, 2);
  assert.equal((await api.get(`/ai/assistant/conversations/${id}`, { token: seller })).status, 404);
  assert.deepEqual((await api.get('/ai/assistant/conversations', { token: buyer })).body.data, [{ id, title: 'Tìm bàn' }]);
  assert.deepEqual((await api.get('/ai/assistant/conversations', { token: seller })).body.data, []);
  assert.equal((await api.delete(`/ai/assistant/conversations/${id}`, { token: seller })).status, 404);
});

test('SSE replay returns only the committed answer and retains ownership and authentication guards', async () => {
  const id = randomUUID(), requestId = randomUUID(), message = 'Xin chào';
  const reply = await send('user-buyer', id, requestId, message, new ScriptedProvider());
  const enabled = process.env.AI_ENABLED, key = process.env.GEMINI_API_KEY;
  process.env.AI_ENABLED = 'true'; process.env.GEMINI_API_KEY = 'test-key-never-called';
  try {
    const path = `/ai/assistant/conversations/${id}/messages/stream`;
    assert.equal((await api.post(path, { body: { requestId, message } })).status, 401);
    assert.equal((await api.post(path, { token: seller, body: { requestId, message } })).status, 404);
    const response = await api.post(path, { token: buyer, body: { requestId, message } });
    assert.equal(response.status, 200);
    assert.ok(response.headers.get('content-type')?.startsWith('text/event-stream'));
    const events = String(response.body).split('\n').filter((line) => line.startsWith('data:')).map((line) => JSON.parse(line.slice(5)));
    assert.deepEqual(events, [{ type: 'done', reply }]);
    assert.equal((await prisma.aiUsage.findUniqueOrThrow({ where: { userId: 'user-buyer' } })).windowCount, 1);
  } finally {
    if (enabled === undefined) delete process.env.AI_ENABLED; else process.env.AI_ENABLED = enabled;
    if (key === undefined) delete process.env.GEMINI_API_KEY; else process.env.GEMINI_API_KEY = key;
  }
});



test('conversation lock rejects concurrent work and cannot be released by another lease', async () => {
  const id = randomUUID();
  const first = await conversations.begin('user-buyer', id, randomUUID(), 'hello');
  await assert.rejects(conversations.begin('user-buyer', id, randomUUID(), 'hello again'), { code: 'AI_BUSY' });
  await conversations.release(id, 'wrong');
  await assert.rejects(conversations.begin('user-buyer', id, randomUUID(), 'hello again'), { code: 'AI_BUSY' });
  await conversations.release(id, first.lease!);
  await conversations.begin('user-buyer', id, randomUUID(), 'hello again');
});

test('failed provider releases lease without saving fabricated answer or draft', async () => {
  const provider = new ScriptedProvider();
  provider.generate = async () => { throw new Error('private upstream error'); };
  const id = randomUUID();
  await assert.rejects(send('user-buyer', id, randomUUID(), 'Mình cần tìm xe đạp cũ', provider), { code: 'AI_UNAVAILABLE' });
  assert.equal(await prisma.aiTurn.count(), 0); assert.equal(await prisma.aiAction.count(), 0);
  assert.equal((await prisma.aiConversation.findUniqueOrThrow({ where: { id } })).lease, null);
});

test('per-user DB rate limit rejects requests across conversations before model call', async () => {
  const now = new Date();
  await prisma.aiUsage.create({ data: { userId: 'user-buyer', windowStart: now, windowCount: 20, dayStart: new Date(now.toISOString().slice(0, 10)), dayCount: 20 } });
  const provider = new ScriptedProvider();
  await assert.rejects(send('user-buyer', randomUUID(), randomUUID(), 'hello', provider), { code: 'AI_RATE_LIMIT' });
  assert.equal(provider.inputs.length, 0);
});

test('tools hide nonpublic listings and never return credentials or street address', async () => {
  const session = new ToolSession('user-buyer', new ScriptedProvider(), AbortSignal.timeout(5000));
  await prisma.listing.update({ where: { id: 'listing-1' }, data: { status: 'HIDDEN' } });
  try {
    assert.deepEqual(await session.execute('listing_details', { ids: ['listing-1'] }), { items: [] });
    const result = JSON.stringify(await session.execute('listing_details', { ids: ['listing-2'] }));
    assert.ok(!result.includes('streetAddress') && !result.includes('password') && !result.includes('ownerId'));
    const quota = await session.execute('my_quota', {}) as { remaining: unknown };
    assert.ok(quota.remaining);
    await assert.rejects(session.execute('my_quota', { userId: 'user-seller' }), AppError);
  } finally { await prisma.listing.update({ where: { id: 'listing-1' }, data: { status: 'AVAILABLE' } }); }
});

test('RAG indexes real approved documents and excludes changed, inactive, deleted or other-model chunks', async () => {
  const provider = new ScriptedProvider();
  const store = new MemoryVectorStore();
  const doc = await prisma.knowledgeDocument.create({ data: { id: 'ai-test-policy', title: 'Hạn mức', content: 'Xem hạn mức hiện tại trong tài khoản.', indexedText: 'han muc', syncedAt: new Date() } });
  await indexDocument('user-admin', doc.id, provider, store);
  const sources = await retrieve('Hạn mức', provider, AbortSignal.timeout(5000), store);
  assert.equal(sources[0].id, doc.id);
  const other = new ScriptedProvider(); other.embeddingModel = 'other';
  assert.deepEqual(await retrieve('Hạn mức', other, AbortSignal.timeout(5000), store), []);
  await prisma.knowledgeDocument.update({ where: { id: doc.id }, data: { content: 'Chính sách mới', updatedAt: new Date(+doc.updatedAt + 1000) } });
  assert.deepEqual(await retrieve('Hạn mức', provider, AbortSignal.timeout(5000), store), []);
  await indexDocument('user-admin', doc.id, provider, store);
  await prisma.knowledgeDocument.update({ where: { id: doc.id }, data: { active: false } });
  assert.deepEqual(await retrieve('Hạn mức', provider, AbortSignal.timeout(5000), store), []);
  await prisma.knowledgeDocument.delete({ where: { id: doc.id } });
  assert.equal(await prisma.aiKnowledgeChunk.count({ where: { documentId: doc.id } }), 0);
  assert.ok(await prisma.aiVectorDeletion.count() > 0);
  await cleanupVectors(store);
  assert.equal(store.points.size, 0);
});

test('Qdrant write failure never publishes SQL index; outbox retries cleanup without losing old generation', async () => {
  const provider = new ScriptedProvider(), store = new MemoryVectorStore();
  const doc = await prisma.knowledgeDocument.create({ data: { id: 'ai-test-failure', title: 'Policy', content: 'Approved policy', indexedText: 'policy' } });
  await indexDocument('user-admin', doc.id, provider, store);
  const oldIds = [...store.points.keys()];
  assert.deepEqual((await prisma.aiKnowledgeChunk.findMany({ where: { documentId: doc.id } }))[0].embedding, []);
  store.failUpsert = true;
  await assert.rejects(indexDocument('user-admin', doc.id, provider, store), { code: 'AI_INDEX_FAILED' });
  assert.equal((await prisma.aiKnowledgeIndex.findUniqueOrThrow({ where: { documentId: doc.id } })).status, 'FAILED');
  assert.deepEqual((await prisma.aiKnowledgeChunk.findMany({ where: { documentId: doc.id } })).map((r) => r.id), oldIds);
  assert.ok((await retrieve('policy', provider, AbortSignal.timeout(5000), store)).length);
  store.failDelete = true;
  await assert.rejects(cleanupVectors(store));
  assert.ok(await prisma.aiVectorDeletion.count() > 0);
  store.failDelete = false;
  await cleanupVectors(store);
  assert.deepEqual([...store.points.keys()], oldIds);
});

test('RAG rejects document changed while embedding and serializes indexing by document', async () => {
  const provider = new ScriptedProvider(), store = new MemoryVectorStore();
  const doc = await prisma.knowledgeDocument.create({ data: { id: 'ai-test-race', title: 'Policy', content: 'Original', indexedText: 'original' } });
  provider.embed = async () => {
    await assert.rejects(indexDocument('user-admin', doc.id, new ScriptedProvider(), store), { code: 'AI_INDEX_BUSY' });
    await prisma.knowledgeDocument.update({ where: { id: doc.id }, data: { content: 'Changed', updatedAt: new Date(+doc.updatedAt + 1000) } });
    return [1, ...Array(767).fill(0)];
  };
  await assert.rejects(indexDocument('user-admin', doc.id, provider, store), { code: 'KNOWLEDGE_CHANGED' });
  assert.equal(await prisma.aiKnowledgeChunk.count({ where: { documentId: doc.id } }), 0);
  await cleanupVectors(store);
  assert.equal(store.points.size, 0);
});
