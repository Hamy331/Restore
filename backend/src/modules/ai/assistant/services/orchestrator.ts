import { AppError } from '../../../../common/errors/app-error.js';
import type { AiProvider, AssistantEvent, Content, Declaration } from '../assistant.type.js';
import { redact, redactValue } from '../../../../common/security/redaction.js';
import { containsInstruction, inputReply, requiredTools } from './input-guard.service.js';
import { guardedAnswer, type Evidence } from './output-guard.service.js';
import { validateTool } from './tools.service.js';

export function boundedHistory(turns: Content[][]): Content[] {
  const selected: Content[][] = [];
  let size = 0;
  for (const turn of [...turns].reverse()) {
    const length = JSON.stringify(turn).length;
    if (size + length > 24_000) break;
    selected.unshift(turn);
    size += length;
  }
  return selected.flat();
}

export async function runAssistant(provider: AiProvider, history: Content[], message: string,
  declarations: Declaration[], execute: (name: string, args: unknown) => Promise<unknown>, signal: AbortSignal, emit?: (event: AssistantEvent) => void, scope?: string[]) {
  signal.throwIfAborted();
  message = redact(message);
  history = redactValue(history);
  const turn: Content[] = [{ role: 'user', parts: [{ text: message }] }];
  const local = inputReply(message, history.length > 0);
  if (local) return { text: local, contents: [...turn, { role: 'model' as const, parts: [{ text: local }] }] };
  const evidence: Evidence[] = [];
  const required = scope ?? requiredTools(message, history);
  const permitted = new Set(required.flatMap(name => name === 'listings' ? ['search_listings', 'listing_details'] : [name]));
  let callCount = 0;
  for (let round = 0; round < 4; round++) {
    signal.throwIfAborted();
    emit?.({ type: 'reset' });
    emit?.({ type: 'status', stage: 'thinking' });
    // Do not stream unverified text: it may contain secrets or fabricated facts.
    // Status events still provide progress while the final answer is checked.
    const answer = await provider.generate([...history, ...turn], declarations, signal, emit ? () => {} : undefined);
    if (JSON.stringify(answer).length > 32_000) throw new AppError(503, 'AI_OUTPUT_LIMIT', 'Câu trả lời AI vượt giới hạn.');
    turn.push(answer);
    const calls = answer.parts.flatMap((part) => part.functionCall ? [part.functionCall] : []);
    if (!calls.length) {
      const text = answer.parts.filter((part) => !part.thought).map((part) => part.text ?? '').join('').trim();
      if (!text || text.length > 8000) throw new AppError(503, 'AI_NO_ANSWER', 'AI chưa tạo được câu trả lời đầy đủ.');
      const evidenceQuestion = scope?.includes('search_knowledge') ? `Chính sách ReStore: ${message}` : scope?.includes('my_quota') ? `Hạn mức của tôi: ${message}` : message;
      const checked = await guardedAnswer(provider, evidenceQuestion, history, text, evidence, signal);
      // Store only approved user-facing prose, never rejected model claims.
      turn[turn.length - 1] = { role: 'model', parts: [{ text: checked }] };
      return { text: checked, contents: redactValue(turn) };
    }
    if ((callCount += calls.length) > 6 || round === 3) throw new AppError(503, 'AI_TOOL_LIMIT', 'Yêu cầu cần quá nhiều thao tác. Bạn thử chia nhỏ câu hỏi nhé.');
    const parts: Content['parts'] = [];
    emit?.({ type: 'reset' });
    for (const call of calls) {
      signal.throwIfAborted();
      let response: unknown;
      const stages = { search_listings: 'searching_listings', listing_details: 'reading_listings', search_knowledge: 'searching_knowledge', my_quota: 'reading_quota' } as const;
      if (call.name in stages) emit?.({ type: 'status', stage: stages[call.name as keyof typeof stages] });
      try {
        if (!declarations.some(tool => tool.name === call.name)) throw new AppError(400, 'AI_TOOL_NOT_ALLOWED', 'Công cụ không được phép.');
        if (permitted.size && !permitted.has(call.name)) throw new AppError(400, 'AI_TOOL_NOT_ALLOWED', 'Công cụ không phù hợp với yêu cầu hiện tại.');
        const args = validateTool(call.name, redactValue(call.args));
        const data = redactValue(await execute(call.name, args)) as Record<string, unknown>;
        // Independent of the tool implementation: never pass obvious retrieved
        // instructions on as evidence, even if a tool adapter forgets to filter.
        if (data && typeof data === 'object') {
          for (const key of ['items', 'sources']) if (Array.isArray(data[key])) {
            data[key] = (data[key] as unknown[]).filter(item => !containsInstruction(JSON.stringify(item)));
          }
        }
        evidence.push({ tool: call.name, data });
        response = { result: data };
      }
      catch (error) {
        if (!(error instanceof AppError) || error.statusCode >= 500) throw error;
        response = { error: { code: error.code, message: error.message } };
      }
      parts.push({ functionResponse: { ...(call.id ? { id: call.id } : {}), name: call.name, response } });
    }
    turn.push({ role: 'user', parts });
  }
  throw new AppError(503, 'AI_TOOL_LIMIT', 'AI chưa hoàn thành yêu cầu.');
}
