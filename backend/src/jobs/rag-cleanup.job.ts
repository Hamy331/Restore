import { cleanupVectors } from '../modules/ai/rag/services/cleanup.service.js';
import { AppError } from '../common/errors/app-error.js';

/** Retry the durable deletion outbox. Safe across instances because point deletion is idempotent. */
export function startRagCleanupJob() {
  if (process.env.AI_ENABLED !== 'true') return;
  let running = false;
  const tick = async () => {
    if (running) return;
    running = true;
    try { await cleanupVectors(); }
    catch (error) {
      console.warn('[ai:rag:cleanup]', error instanceof AppError ? error.code : 'CLEANUP_FAILED');
    } finally { running = false; }
  };
  const timer = setInterval(() => { void tick(); }, 5 * 60_000);
  timer.unref();
  return () => clearInterval(timer);
}
