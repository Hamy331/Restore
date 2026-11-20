import 'dotenv/config';
import { prisma } from '../src/lib/prisma.js';
import { configuredProvider } from '../src/modules/ai/assistant/services/gemini.provider.js';
import { searchListings } from '../src/modules/ai/assistant/services/listing-search.service.js';
import { runAssistant } from '../src/modules/ai/assistant/services/orchestrator.js';
import { declarations, validateTool } from '../src/modules/ai/assistant/services/tools.service.js';
import { searchArgs } from '../src/modules/ai/assistant/assistant.validator.js';
import { AppError } from '../src/common/errors/app-error.js';

// Read-only public catalog smoke test. No user chat, draft or usage record is created.
if (process.env.AI_LIVE_EVAL !== 'true') throw new Error('Set AI_LIVE_EVAL=true for real provider requests.');
try {
  const provider = configuredProvider();
  const sample = await prisma.listing.findFirst({ where: { status: 'AVAILABLE', owner: { status: 'ACTIVE' }, aiIndex: { isNot: null } }, select: { id: true, title: true, price: true, categoryId: true }, orderBy: { id: 'asc' } });
  if (!sample) throw new AppError(409, 'NO_INDEXED_LISTINGS', 'Chưa có tin công khai đã index để kiểm tra.');
  const signal = AbortSignal.timeout(60000);
  const input = { q: sample.title, minPrice: sample.price.toString(), maxPrice: sample.price.toString(), categoryId: sample.categoryId ?? undefined };
  const rows = await searchListings(input, provider, signal);
  if (!rows.some((row) => row.id === sample.id)) throw new Error('Expected listing was not retrieved');
  if (rows.some((row) => row.price !== input.minPrice || row.status !== 'AVAILABLE')) throw new Error('Hard filters failed');
  let deltas = 0, searches = 0;
  const answer = await runAssistant(provider, [], `Tìm giúp tôi ${sample.title}. Giá không quá ${sample.price.toString()} đồng.`, declarations, async (name, args) => {
    validateTool(name, args);
    if (name !== 'search_listings') throw new AppError(400, 'TEST_TOOL_SCOPE', 'Trong ca kiểm thử này chỉ tìm sản phẩm.');
    searches++;
    const listings = await searchListings(searchArgs.parse(args), provider, signal);
    return { items: listings.map(({ id, title, price, areaLabel }) => ({ id, title, price, areaLabel })) };
  }, signal, (event) => { if (event.type === 'delta') deltas++; });
  if (!searches || !deltas || !answer.text) throw new Error('Live tool/stream roundtrip incomplete');
  console.log(JSON.stringify({ hybridListing: 'PASS', currentSqlFilters: 'PASS', streamedToolRoundtrip: 'PASS', searches, textChunks: deltas }));
} catch (error) {
  console.error(JSON.stringify({ code: error instanceof AppError ? error.code : 'LISTING_SMOKE_FAILED' }));
  process.exitCode = 1;
} finally { await prisma.$disconnect(); }
