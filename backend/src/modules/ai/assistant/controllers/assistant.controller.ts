import type { Response } from 'express';
import type { AuthRequest } from '../../../../middlewares/auth.middleware.js';
import { noContent, ok } from '../../../../common/http/response.js';
import { parse } from '../../../../common/validation/schemas.js';
import { conversationId, messageBody, noArgs } from '../assistant.validator.js';
import * as service from '../services/assistant.service.js';
import * as repository from '../repositories/assistant.repository.js';
import { AppError } from '../../../../common/errors/app-error.js';

export async function send(req: AuthRequest, res: Response) {
  const id = parse(conversationId, req.params.id);
  const { requestId, message } = parse(messageBody, req.body);
  ok(res, await service.send(req.user!.userId, id, requestId, message));
}
export async function stream(req: AuthRequest, res: Response) {
  const id = parse(conversationId, req.params.id);
  const { requestId, message } = parse(messageBody, req.body);
  const abort = new AbortController();
  const close = () => { if (!res.writableEnded) abort.abort(); };
  res.on('close', close);
  const write = (event: unknown) => {
    if (res.destroyed || abort.signal.aborted) return;
    if (!res.headersSent) {
      res.set({ 'Content-Type': 'text/event-stream; charset=utf-8', 'Cache-Control': 'no-cache, no-transform', 'X-Accel-Buffering': 'no' });
      res.flushHeaders();
    }
    res.write(`data: ${JSON.stringify(event)}\n\n`);
    if (res.writableLength > 128000) { abort.abort(); res.destroy(); }
  };
  try {
    const reply = await service.send(req.user!.userId, id, requestId, message, undefined, { emit: write, signal: abort.signal });
    write({ type: 'done', reply });
  } catch (error) {
    if (!res.headersSent && !res.destroyed) throw error;
    const safe = error instanceof AppError ? error : new AppError(503, 'AI_UNAVAILABLE', 'AI chưa thể trả lời. Bạn thử lại nhé.');
    write({ type: 'error', code: safe.code, message: safe.message });
  } finally { res.off('close', close); if (res.headersSent && !res.destroyed) res.end(); }
}
export async function list(req: AuthRequest, res: Response) {
  const after = req.query.after === undefined ? undefined : parse(conversationId, req.query.after);
  ok(res, await repository.listRecent(req.user!.userId, after));
}
export async function history(req: AuthRequest, res: Response) {
  ok(res, await repository.history(req.user!.userId, parse(conversationId, req.params.id)));
}
export async function remove(req: AuthRequest, res: Response) {
  await repository.remove(req.user!.userId, parse(conversationId, req.params.id));
  noContent(res);
}
