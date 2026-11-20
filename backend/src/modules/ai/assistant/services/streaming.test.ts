import assert from 'node:assert/strict';
import { test } from 'node:test';
import { GeminiProvider } from './gemini.provider.js';
import { runAssistant } from './orchestrator.js';
import { declarations } from './tools.service.js';
import type { AssistantEvent } from '../assistant.type.js';

const signal = () => AbortSignal.timeout(5000);
function streamed(events: unknown[]) {
  const bytes = new TextEncoder().encode(events.map((event) => `data: ${JSON.stringify(event)}\r\n\r\n`).join(''));
  return new Response(new ReadableStream({ start(controller) {
    for (let offset = 0; offset < bytes.length; offset += 7) controller.enqueue(bytes.slice(offset, offset + 7));
    controller.close();
  } }));
}
test('Gemini stream retains tool signatures and buffers text until grounding is verified', async () => {
  let round = 0;
  const provider = new GeminiProvider('test', async (url, options) => {
    if (String(url).endsWith(':generateContent')) return Response.json({ candidates: [{ finishReason: 'STOP', content: { role: 'model', parts: [{ text: '{"supported":true}' }] } }] });
    assert.ok(String(url).endsWith(':streamGenerateContent?alt=sse'));
    if (++round === 1) return streamed([{ candidates: [{ finishReason: 'STOP', content: { role: 'model', parts: [
      { text: 'internal', thought: true }, { thoughtSignature: 'signed', functionCall: { id: 'call1', name: 'my_quota', args: {} } },
    ] } }] }]);
    const body = JSON.parse(String(options?.body));
    assert.equal(body.contents[1].parts[1].thoughtSignature, 'signed');
    assert.equal(body.contents[2].parts[0].functionResponse.id, 'call1');
    return streamed([
      { candidates: [{ content: { role: 'model', parts: [{ text: 'Bạn còn ' }] } }] },
      { candidates: [{ finishReason: 'STOP', content: { role: 'model', parts: [{ text: '2 lượt.' }] } }] },
    ]);
  });
  const events: AssistantEvent[] = [];
  const result = await runAssistant(provider, [], 'Còn mấy lượt?', declarations, async () => ({ remaining: 2 }), signal(), (event) => events.push(event));
  assert.equal(result.text, 'Bạn còn 2 lượt.');
  assert.deepEqual(events.filter((event) => event.type === 'delta'), []);
  assert.ok(events.some((event) => event.type === 'status' && event.stage === 'reading_quota'));
});

test('truncated provider stream never becomes a completed answer', async () => {
  const provider = new GeminiProvider('test', async () => streamed([{ candidates: [{ content: { role: 'model', parts: [{ text: 'partial' }] } }] }]));
  await assert.rejects(provider.generate([], declarations, signal(), () => {}), { code: 'AI_NO_ANSWER' });
});
