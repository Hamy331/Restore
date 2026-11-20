import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { z } from 'zod';
import { prisma } from '../src/lib/prisma.js';
import { audit } from '../src/common/audit/admin-audit.js';
import { AppError } from '../src/common/errors/app-error.js';
import { withQuotaTransaction } from '../src/modules/commerce/index.js';
import { normalizeKnowledge } from '../src/modules/content/content.validator.js';
import { GeminiProvider } from '../src/modules/ai/assistant/services/gemini.provider.js';
import { indexDocument, retrieve } from '../src/modules/ai/rag/services/rag.service.js';
import { configuredVectorStore } from '../src/modules/ai/rag/repositories/qdrant.repository.js';

const documents = z.array(z.object({
  id: z.string().regex(/^restore-bootstrap-[a-z-]+-v1$/), title: z.string().min(1), content: z.string().min(20),
  codeSources: z.array(z.string()), checkQuery: z.string().min(2),
})).parse(JSON.parse(await readFile(new URL('../knowledge/bootstrap.json', import.meta.url), 'utf8')));
const apply = process.argv.includes('--apply'), verify = process.argv.includes('--verify');
const actor = 'system:restore-ai-bootstrap';

try {
  if (!apply && !verify) {
    console.log(JSON.stringify({ dryRun: true, documents: documents.map(({ id, title, codeSources }) => ({ id, title, codeSources })) }));
  } else {
    if (!process.env.GEMINI_API_KEY) throw new Error('Gemini key is required');
    const provider = new GeminiProvider(process.env.GEMINI_API_KEY), store = configuredVectorStore();
    if (apply) {
      await store.ensureCollection(AbortSignal.timeout(30000));
      for (const source of documents) {
        const doc = await withQuotaTransaction(async (tx) => {
          const existing = await tx.knowledgeDocument.findUnique({ where: { id: source.id } });
          if (existing) return existing;
          const created = await tx.knowledgeDocument.create({ data: {
            id: source.id, title: source.title, content: source.content, active: true,
            indexedText: normalizeKnowledge(source.title + '\n' + source.content), syncedAt: new Date(),
          } });
          await audit(tx, actor, 'BOOTSTRAP', 'KNOWLEDGE', created.id, 'Code-derived starter guide requested by project owner; not a pricing policy', undefined, { codeSources: source.codeSources });
          return created;
        });
        // Never overwrite admin edits or reactivate a source they disabled. Re-running can retry failed indexes.
        if (doc.title !== source.title || doc.content !== source.content || !doc.active || doc.indexedText === null) {
          console.log(JSON.stringify({ id: source.id, skipped: 'existing document differs or was disabled' }));
          continue;
        }
        console.log(JSON.stringify(await indexDocument(actor, doc.id, provider, store)));
      }
    }
    if (verify) {
      for (const source of documents) {
        const hits = await retrieve(source.checkQuery, provider, AbortSignal.timeout(30000), store);
        const found = hits[0]?.id === source.id;
        console.log(JSON.stringify({ id: source.id, retrievalTop1: found ? 'PASS' : 'FAIL', sources: hits.map((hit) => hit.id) }));
        if (!found) process.exitCode = 1;
      }
    }
  }
} catch (error) {
  console.error(JSON.stringify({ code: error instanceof AppError ? error.code : 'BOOTSTRAP_FAILED' }));
  process.exitCode = 1;
} finally { await prisma.$disconnect(); }
