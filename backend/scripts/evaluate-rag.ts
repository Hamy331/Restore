import 'dotenv/config';
import { randomUUID } from 'node:crypto';
import { AppError } from '../src/common/errors/app-error.js';

// Real Gemini + Qdrant, but SQL fixtures are restricted to a disposable local database.
const testUrl = process.env.TEST_DATABASE_URL;
if (process.env.AI_LIVE_EVAL !== 'true' || !testUrl || !['127.0.0.1', 'localhost', '::1', '[::1]'].includes(new URL(testUrl).hostname)) {
  throw new Error('Requires AI_LIVE_EVAL=true and a local TEST_DATABASE_URL. Never use the shared Supabase database.');
}
process.env.DATABASE_URL = testUrl; process.env.DIRECT_URL = testUrl;
const { prisma } = await import('../src/lib/prisma.js');
const { GeminiProvider } = await import('../src/modules/ai/assistant/services/gemini.provider.js');
const { configuredVectorStore } = await import('../src/modules/ai/rag/repositories/qdrant.repository.js');
const { indexDocument, retrieve } = await import('../src/modules/ai/rag/services/rag.service.js');
const { cleanupVectors } = await import('../src/modules/ai/rag/services/cleanup.service.js');
if (!process.env.GEMINI_API_KEY) throw new Error('Missing GEMINI_API_KEY');
const provider = new GeminiProvider(process.env.GEMINI_API_KEY);
const store = configuredVectorStore();
const id = `rag-eval-${randomUUID()}`;
try {
  const actor = await prisma.user.findFirst({ where: { role: 'ADMIN', status: 'ACTIVE' }, select: { id: true } });
  if (!actor) throw new Error('Seed local API fixtures first.');
  await prisma.knowledgeDocument.create({ data: {
    id, title: 'Tài liệu kiểm thử truy xuất, không phải chính sách chính thức',
    content: 'Trong tình huống kiểm thử này, người bán phải thêm ít nhất một ảnh sản phẩm trước khi gửi tin để duyệt. Tin nháp có thể lưu khi chưa đầy đủ ảnh.',
    indexedText: 'tai lieu kiem thu anh san pham tin nhap', active: true, syncedAt: new Date(),
  } });
  await indexDocument(actor.id, id, provider, store);
  const sources = await retrieve('Chưa chụp hình món hàng thì có gửi tin để xét duyệt được không?', provider, AbortSignal.timeout(30000), store);
  if (!sources.some((source) => source.id === id)) throw new Error('Expected source was not retrieved');
  await prisma.knowledgeDocument.update({ where: { id }, data: { active: false } });
  const hidden = await retrieve('Muốn gửi tin duyệt thì cần ảnh không?', provider, AbortSignal.timeout(30000), store);
  if (hidden.some((source) => source.id === id)) throw new Error('Inactive source leaked');
  console.log('PASS: real Gemini embedding -> Qdrant -> authorized SQL context; inactive source excluded.');
} catch (error) {
  console.error(JSON.stringify({ code: error instanceof AppError ? error.code : 'RAG_EVALUATION_FAILED' }));
  process.exitCode = 1;
} finally {
  try {
    await prisma.knowledgeDocument.deleteMany({ where: { id } });
    await cleanupVectors(store);
    console.log('Local source and Cloud test vectors cleaned up.');
  } catch { console.error(`RAG test cleanup pending for document ${id}`); process.exitCode = 1; }
  await prisma.$disconnect();
}
