import { AppError } from '../common/errors/app-error.js';
import { configuredProvider } from '../modules/ai/assistant/services/gemini.provider.js';
import { reviewPendingListings } from '../modules/listings/services/ai-review.service.js';

/** Mỗi phút cho AI xem ảnh và nội dung vài tin chờ duyệt (khi bật AI_ENABLED) */
export function startListingAiReviewJob(intervalMs = 60_000) {
  if (process.env.AI_ENABLED !== 'true') return;
  let running = false;
  const tick = async () => {
    if (running) return;
    running = true;
    try { await reviewPendingListings(configuredProvider()); }
    catch (error) { console.warn('[ai:listings:review]', error instanceof AppError ? error.code : 'REVIEW_FAILED'); }
    finally { running = false; }
  };
  const timer = setInterval(() => { void tick(); }, intervalMs);
  timer.unref();
  return () => clearInterval(timer);
}
