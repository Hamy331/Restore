import { AppError } from '../../../../common/errors/app-error.js';
import type { AiProvider, AssistantEvent, Content } from '../assistant.type.js';
import * as repository from '../repositories/assistant.repository.js';
import { configuredProvider } from './gemini.provider.js';
import { boundedHistory, runAssistant } from './orchestrator.js';
import { declarations, ToolSession } from './tools.service.js';
import { redact, redactValue } from '../../../../common/security/redaction.js';
import { localDecision, extractDecision } from './dialogue.service.js';
import { readState } from './conversation-state.js';
import { activeCategories } from '../repositories/dialogue.repository.js';
import { executeShopping } from './shopping-dialogue.service.js';
import type { AssistantReply } from '../assistant.type.js';
import { channel } from 'node:diagnostics_channel';

const turnMetrics = channel('restore.ai.dialogue');

export async function send(userId: string, id: string, requestId: string, message: string, provider?: AiProvider, options: { emit?: (event: AssistantEvent) => void; signal?: AbortSignal } = {}) {
  const startedAt = performance.now();
  let extractionCalls = 0;
  message = redact(message);
  const started = await repository.begin(userId, id, requestId, message);
  if (started.cached) return redactValue(started.cached);
  const lease = started.lease!;
  try {
    const signal = AbortSignal.any([AbortSignal.timeout(60_000), ...(options.signal ? [options.signal] : [])]);
    signal.throwIfAborted();
    const previous = readState(started.state);
    let decision = localDecision(previous, message);
    if (!decision) {
      provider ??= configuredProvider();
      options.emit?.({ type: 'status', stage: 'thinking' });
      extractionCalls = provider.extractNeeds ? 1 : 0;
      decision = await extractDecision(previous, message, provider, provider.extractNeeds ? await activeCategories() : [], signal);
    }
    const commit = async (reply: AssistantReply, contents: Content[] = [
      { role: 'user', parts: [{ text: message }] }, { role: 'model', parts: [{ text: reply.text }] },
    ]) => {
      signal.throwIfAborted();
      const saved = await repository.finish(id, lease, requestId, message, redactValue(reply), contents, undefined, decision!.state);
      turnMetrics.publish({ outcome: 'completed', elapsedMs: Math.round(performance.now() - startedAt), extractionCalls, intent: decision!.state.intent, unclearCount: decision!.state.unclearCount, pending: decision!.state.pending, resultCount: reply.listings.length });
      return saved;
    };
    if (decision.reply) return await commit(decision.reply);
    provider ??= configuredProvider();
    const session = new ToolSession(userId, provider, signal);
    if (decision.cheaper || decision.search || decision.details) {
      await executeShopping(decision, session, options.emit, signal);
      return await commit(session.reply);
    }
    const history = redactValue(boundedHistory((await repository.recentTurns(id)).reverse().map((turn) => turn.contents as unknown as Content[])));
    const scope = decision.state.intent === 'knowledge' ? ['search_knowledge'] : decision.state.intent === 'quota' ? ['my_quota'] : undefined;
    const result = await runAssistant(provider, history, message, declarations, (name, args) => session.execute(name, args), signal, options.emit, scope);
    session.reply.text = result.text;
    return await commit(session.reply, result.contents);
  } catch (error) {
    turnMetrics.publish({ outcome: 'error', elapsedMs: Math.round(performance.now() - startedAt), extractionCalls });
    await repository.release(id, lease);
    if (error instanceof AppError) throw error;
    throw new AppError(503, 'AI_UNAVAILABLE', 'AI chưa thể trả lời lúc này. Vui lòng thử lại.');
  }
}

