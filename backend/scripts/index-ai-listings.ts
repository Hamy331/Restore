import 'dotenv/config';
import { prisma } from '../src/lib/prisma.js';
import { configuredProvider } from '../src/modules/ai/assistant/services/gemini.provider.js';
import { syncListingIndex } from '../src/modules/ai/assistant/services/listing-index.service.js';
import { AppError } from '../src/common/errors/app-error.js';

try {
  const provider = configuredProvider();
  let result;
  do {
    result = await syncListingIndex(provider);
    console.log(JSON.stringify(result));
    // Each batch has a deadline; explicit --all drains pending records.
  } while (process.argv.includes('--all') && result.scanned > 0 && result.indexed > 0);
} catch (error) {
  console.error(JSON.stringify({ code: error instanceof AppError ? error.code : 'LISTING_INDEX_FAILED' }));
  process.exitCode = 1;
} finally { await prisma.$disconnect(); }
