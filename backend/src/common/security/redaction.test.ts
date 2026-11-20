import assert from 'node:assert/strict';
import { test } from 'node:test';
import { EventEmitter } from 'node:events';
import { apiLogger } from '../../middlewares/logger.middleware.js';
import { errorHandler } from '../../middlewares/error.middleware.js';

test('request logs omit query secrets and redact private details in errors', t => {
  const logs: string[] = [];
  t.mock.method(console, 'log', (message: string) => logs.push(message));
  const response = Object.assign(new EventEmitter(), { statusCode: 400, json: (body: unknown) => body });
  apiLogger({ method: 'POST', originalUrl: '/api/v1/ai?api_key=private-key' } as never, response as never, () => {});
  response.json({ error: 'Bad token: private-token and me@example.com' });
  response.emit('finish');
  assert.ok(logs[0].includes('/api/v1/ai'));
  for (const secret of ['private-key', 'private-token', 'me@example.com', '?api_key']) assert.ok(!logs[0].includes(secret));
});

test('unhandled errors never dump request bodies, exception messages or causes', t => {
  const logs: unknown[] = [];
  t.mock.method(console, 'error', (...args: unknown[]) => logs.push(args));
  const error = new Error('password=very-secret', { cause: { body: 'Bearer private-secret' } });
  const res = { status: (_code: number) => res, json: (_body: unknown) => res };
  errorHandler(error, {} as never, res as never, () => {});
  const serialized = JSON.stringify(logs);
  assert.ok(!serialized.includes('very-secret')); assert.ok(!serialized.includes('private-secret'));
});
