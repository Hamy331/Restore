import { AppError } from '../common/errors/app-error.js';
import { configuredProvider } from '../modules/ai/assistant/services/gemini.provider.js';
import { syncListingIndex } from '../modules/ai/assistant/services/listing-index.service.js';
import { listingIndexConfig } from '../modules/ai/ai.config.js';

export function startListingAiIndexJob() {
  if (process.env.AI_ENABLED !== 'true') return;
  let running = false;
  const tick = async () => {
    if (running) return;
    running = true;
    try { await syncListingIndex(configuredProvider()); }
    catch (error) { console.warn('[ai:listings:index]', error instanceof AppError ? error.code : 'INDEX_FAILED'); }
    finally { running = false; }
  };
  const timer = setInterval(() => { void tick(); }, listingIndexConfig().AI_LISTING_INDEX_INTERVAL_MS);
  timer.unref();
  return () => clearInterval(timer);
}
