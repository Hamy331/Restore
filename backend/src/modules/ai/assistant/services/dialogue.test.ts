import assert from 'node:assert/strict';
import { test } from 'node:test';
import { applyExtraction, emptyState, readState } from './conversation-state.js';
import { decide, extractDecision, localDecision } from './dialogue.service.js';
import type { AiProvider } from '../assistant.type.js';
import { GeminiProvider } from './gemini.provider.js';

test('Vietnamese conversation requests get a local answer and preserve the shopping context', () => {
  const state = decide(emptyState(), { intent: 'shopping', slots: { query: 'laptop' }, newSearch: true, searchNow: false }).state;
  for (const message of ['Nói tiếng việt đc ko', 'Bạn nói được tiếng Việt không?', 'Can you speak Vietnamese?']) {
    const result = localDecision(state, message);
    assert.match(result?.reply?.text ?? '', /tiếng Việt/);
    assert.deepEqual(result?.state, state);
  }
  assert.equal(localDecision(state, 'Tìm sách học nói tiếng Việt'), undefined);
});

const shopping = (slots: any, newSearch = false, searchNow = true) => ({ intent: 'shopping' as const, slots, newSearch, searchNow });

test('budget filling, corrections, unlimited and search-now never re-ask known slots', () => {
  const first = decide(emptyState(), shopping({ query: 'điện thoại', categoryId: 'phones', brand: 'Samsung' }, true, false));
  assert.equal(first.state.pending, 'budget');
  const second = localDecision(first.state, '5 triệu')!;
  assert.equal(second.search?.maxPrice, '5000000');
  assert.equal(second.search?.brand, 'Samsung');
  assert.equal(second.state.pending, null);
  assert.equal(localDecision(second.state, 'tăng lên 7 triệu')?.search?.maxPrice, '7000000');
  assert.equal(localDecision(second.state, 'hãng nào cũng được')?.search?.brand, undefined);
  assert.equal(localDecision(second.state, 'không giới hạn ngân sách')?.state.slots.maxPrice, null);
  assert.ok(localDecision(first.state, 'tìm luôn')?.search);
  assert.match(localDecision(first.state, '5')!.reply!.text, /đồng, nghìn hay triệu/);
});

test('all categories share the reducer; attributes merge and product switches clear old constraints', () => {
  const phone = applyExtraction(emptyState(), shopping({ query: 'điện thoại', categoryId: 'phones', brand: 'Samsung', maxPrice: '5000000' }));
  const chair = decide(phone, shopping({ query: 'ghế', categoryId: 'furniture', attributes: { material: 'gỗ' } }, true, false));
  assert.equal(chair.state.slots.brand, undefined);
  assert.equal(chair.state.slots.maxPrice, undefined);
  const next = decide(chair.state, shopping({ attributes: { width: '80 cm' }, maxPrice: '1000000' }));
  assert.deepEqual(next.state.slots.attributes, { material: 'gỗ', width: '80 cm' });
  assert.match(next.search!.q, /gỗ.*80 cm/);
  assert.deepEqual(phone.slots.brand, 'Samsung');
});

test('ordinal references retain display order; invalid selections ask instead of guessing', () => {
  const state = { ...emptyState(), results: ['b', 'a', 'c'] };
  assert.deepEqual(localDecision(state, 'cái thứ hai')?.details, ['a']);
  assert.deepEqual(localDecision(state, 'so sánh cái đầu và cái thứ ba')?.details, ['b', 'c']);
  assert.ok(localDecision(state, 'cái thứ 8')?.reply);
  assert.ok(localDecision(state, 'rẻ hơn chút')?.reply);
  assert.equal(localDecision({ ...state, selected: ['a'] }, 'rẻ hơn chút')?.cheaper, 'a');
});

test('repeated noise escalates to suggestions without losing the pending budget', () => {
  let state = decide(emptyState(), shopping({ query: 'sách' }, true, false)).state;
  for (let i = 1; i <= 3; i++) {
    const d = localDecision(state, 'asdfgh')!;
    state = d.state;
    assert.equal(state.unclearCount, i);
    assert.equal(state.pending, 'budget');
    assert.equal(state.slots.query, 'sách');
    if (i === 3) assert.equal(d.reply!.suggestions!.length, 3);
  }
  const valid = localDecision(state, '100 nghìn')!;
  assert.equal(valid.state.unclearCount, 0);
  assert.equal(valid.search?.maxPrice, '100000');
  assert.deepEqual(localDecision(valid.state, 'Bắt đầu lại')?.state, emptyState());
});

test('quota/policy switches preserve shopping constraints and clear pending questions', () => {
  const state = decide(emptyState(), shopping({ query: 'laptop', maxPrice: '8000000' })).state;
  const quota = localDecision(state, 'Còn bao nhiêu lượt đăng?')!.state;
  assert.equal(quota.intent, 'quota');
  assert.equal(quota.slots.maxPrice, '8000000');
  assert.equal(localDecision(quota, 'tiếp tục tìm')?.search?.maxPrice, '8000000');
  assert.deepEqual(readState({}), emptyState());
  assert.deepEqual(readState({ version: 99 }), emptyState());
});

test('validated extraction uses live category attributes; rejects invented keys and malformed results', async () => {
  const provider: AiProvider = { embeddingModel: 'test', embed: async () => [], generate: async () => { throw Error('unexpected'); }, extractNeeds: async () => shopping({ query: 'bàn', categoryId: 'furniture', attributes: { material: 'gỗ' } }) };
  const categories = [{ id: 'furniture', name: 'Nội thất', attributes: [{ key: 'material' }] }];
  const signal = AbortSignal.timeout(5000);
  assert.ok((await extractDecision(emptyState(), 'bàn gỗ', provider, categories, signal)).search);
  provider.extractNeeds = async () => shopping({ categoryId: 'fake' });
  assert.ok((await extractDecision(emptyState(), 'bàn', provider, categories, signal)).reply);
  provider.extractNeeds = async () => shopping({ categoryId: 'furniture', attributes: { hacked: 'yes' } });
  assert.ok((await extractDecision(emptyState(), 'bàn', provider, categories, signal)).reply);
  provider.extractNeeds = async () => ({ intent: 'shopping', slots: { userId: 'other' } });
  assert.deepEqual((await extractDecision(emptyState(), 'bàn', provider, categories, signal)).state, emptyState());
});

test('Gemini extraction is structured, redacted, tool-free and rejects executable output', async () => {
  let body: any;
  let answer: any = { role: 'model', parts: [{ text: JSON.stringify(shopping({ query: 'sách', maxPrice: '200000' })) }] };
  const provider = new GeminiProvider('test-key', (async (_url: unknown, options: RequestInit) => {
    body = JSON.parse(options.body as string);
    return new Response(JSON.stringify({ candidates: [{ finishReason: 'STOP', content: answer }] }));
  }) as typeof fetch);
  const result = await provider.extractNeeds({ message: 'Tìm sách, token: my-secret-token-123' }, AbortSignal.timeout(5000));
  assert.equal(extractionSchemaForTest(result), true);
  assert.equal(body.tools, undefined);
  assert.equal(body.generationConfig.responseMimeType, 'application/json');
  assert.ok(body.generationConfig.responseJsonSchema);
  assert.doesNotMatch(JSON.stringify(body), /my-secret-token-123/);
  answer = { role: 'model', parts: [{ functionCall: { name: 'my_quota', args: {} } }] };
  assert.equal(await provider.extractNeeds({}, AbortSignal.timeout(5000)), null);
});

function extractionSchemaForTest(value: unknown) { return !!value && (value as any).intent === 'shopping'; }
