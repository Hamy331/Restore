import assert from 'node:assert/strict';
import { test } from 'node:test';
import { AppError } from '../../../../common/errors/app-error.js';
import type { AiProvider, Content } from '../assistant.type.js';
import { boundedHistory, runAssistant } from './orchestrator.js';
import { declarations, validateTool } from './tools.service.js';
import { GeminiProvider } from './gemini.provider.js';

const signal = () => AbortSignal.timeout(5000);
test('tool allowlist rejects cross-account arguments, SQL, excessive comparisons and unknown tools', () => {
  for (const [name, args] of [
    ['my_quota', { userId: 'victim' }], ['search_listings', { q: 'phone', sql: 'SELECT password FROM User' }],
    ['delete_user', {}], ['listing_details', { ids: ['1', '2', '3', '4'] }],
    ['prepare_draft', { title: 'Good title', description: 'Good description', price: '1000000' }],
  ] as const) assert.throws(() => validateTool(name, args), AppError);
  assert.ok(!declarations.some((tool) => tool.name === 'prepare_draft'));
  assert.deepEqual(validateTool('my_quota', {}), {});
});

test('function response preserves call id and signed model content, then answers with tool data', async () => {
  const call: Content = { role: 'model', parts: [{ thoughtSignature: 'signed', functionCall: { id: 'c1', name: 'my_quota', args: {} } }] };
  let round = 0;
  const provider: AiProvider = {
    verifyGrounding: async () => true,
    embeddingModel: 'test', embed: async () => [],
    generate: async (contents) => {
      if (++round === 1) return call;
      assert.deepEqual(contents[1], call);
      assert.deepEqual(contents[2].parts[0].functionResponse, { id: 'c1', name: 'my_quota', response: { result: { drafts: 2 } } });
      return { role: 'model', parts: [{ text: 'Bạn còn 2 bản nháp.' }] };
    },
  };
  const result = await runAssistant(provider, [], 'Còn mấy nháp?', declarations, async () => ({ drafts: 2 }), signal());
  assert.equal(result.text, 'Bạn còn 2 bản nháp.');
});

test('context retains complete tool exchanges for follow-up and drops whole oldest turns at budget', () => {
  const old: Content[] = [{ role: 'user', parts: [{ text: 'a'.repeat(25000) }] }];
  const current: Content[] = [{ role: 'user', parts: [{ text: 'Samsung dưới 5 triệu' }] }, { role: 'model', parts: [{ text: 'Có 2 tin.' }] }];
  assert.deepEqual(boundedHistory([old, current]), current);
});

test('runaway tool calls and exhausted deadlines stop before further execution', async () => {
  let calls = 0;
  const provider: AiProvider = { embeddingModel: 'test', embed: async () => [], generate: async () => ({ role: 'model', parts: [{ functionCall: { name: 'my_quota', args: {} } }] }) };
  await assert.rejects(runAssistant(provider, [], 'x', declarations, async () => { calls++; return {}; }, signal()), { code: 'AI_TOOL_LIMIT' });
  assert.equal(calls, 3);
  const controller = new AbortController(); controller.abort();
  await assert.rejects(runAssistant(provider, [], 'x', declarations, async () => { calls++; }, controller.signal));
  assert.equal(calls, 3);
});

test('Gemini uses separate system instructions, key header and no embedding taskType; rejects blocked/truncated output', async () => {
  const fetcher: typeof fetch = async (url, options) => {
    assert.ok(String(url).startsWith('https://generativelanguage.googleapis.com/'));
    assert.equal((options?.headers as Record<string, string>)['x-goog-api-key'], 'test-key');
    const body = JSON.parse(String(options?.body));
    if (String(url).endsWith(':embedContent')) {
      assert.equal(body.outputDimensionality, 768);
      assert.equal(body.taskType, undefined);
      return Response.json({ embedding: { values: Array(768).fill(0.5) } });
    }
    assert.ok(body.systemInstruction.parts[0].text.includes('ReStore'));
    assert.equal(body.contents[0].parts[0].text, 'hello');
    return Response.json({ candidates: [{ finishReason: 'SAFETY' }] });
  };
  const provider = new GeminiProvider('test-key', fetcher);
  assert.equal((await provider.embed('policy', signal())).length, 768);
  await assert.rejects(provider.generate([{ role: 'user', parts: [{ text: 'hello' }] }], declarations, signal()), { code: 'AI_NO_ANSWER' });
});

test('provider error never leaks raw upstream text or keys', async () => {
  const provider = new GeminiProvider('secret', async () => new Response('sensitive upstream body', { status: 429 }));
  await assert.rejects(provider.embed('x', signal()), (error: unknown) => error instanceof AppError && !error.message.includes('sensitive') && !error.message.includes('secret'));
});
