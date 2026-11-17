import assert from 'node:assert/strict';
import { test } from 'node:test';
import { GeminiProvider, configuredProvider } from './gemini.provider.js';

test('provider sends instructions, preserves signed tool parts and redacts secrets', async () => {
  let sent: any;
  const provider = new GeminiProvider('server-key', (async (_url, options) => {
    sent = JSON.parse(options!.body as string);
    assert.equal((options!.headers as any)['x-goog-api-key'], 'server-key');
    return new Response(JSON.stringify({ candidates: [{ finishReason: 'STOP', content: { role: 'model', parts: [{ thoughtSignature: 'signed', functionCall: { id: 'c1', name: 'read', args: {} } }] } }] }));
  }) as typeof fetch);
  const result = await provider.generate([{ role: 'user', parts: [{ text: 'token: private-token-123' }] }], [], AbortSignal.timeout(5000));
  assert.ok(sent.systemInstruction.parts[0].text);
  assert.doesNotMatch(JSON.stringify(sent), /private-token-123/);
  assert.equal(result.parts[0].thoughtSignature, 'signed');
  assert.equal(result.parts[0].functionCall?.id, 'c1');
});

test('embedding rejects invalid dimensions and zero vectors', async () => {
  let values = Array(768).fill(1);
  const provider = new GeminiProvider('key', (async () => new Response(JSON.stringify({ embedding: { values } }))) as typeof fetch);
  assert.equal((await provider.embed('ghế', AbortSignal.timeout(5000))).length, 768);
  for (const invalid of [Array(768).fill(0), [1]]) {
    values = invalid;
    await assert.rejects(provider.embed('ghế', AbortSignal.timeout(5000)), { code: 'AI_EMBEDDING_INVALID' });
  }
});

test('upstream errors do not disclose provider bodies or keys', async () => {
  const provider = new GeminiProvider('secret-server-key', (async () => new Response('secret-server-key upstream body', { status: 429 })) as typeof fetch);
  await assert.rejects(provider.generate([], [], AbortSignal.timeout(5000)), (error: any) => {
    assert.equal(error.code, 'AI_PROVIDER_RATE_LIMIT');
    assert.doesNotMatch(error.message, /secret-server-key|upstream body/); return true;
  });
});

test('disabled provider fails explicitly', t => {
  const enabled = process.env.AI_ENABLED;
  t.after(() => { if (enabled === undefined) delete process.env.AI_ENABLED; else process.env.AI_ENABLED = enabled; });
  process.env.AI_ENABLED = 'false';
  assert.throws(configuredProvider, { code: 'AI_NOT_CONFIGURED' });
});
