import { randomUUID } from 'node:crypto';
import { prisma } from '../../../../lib/prisma.js';
import { AppError } from '../../../../common/errors/app-error.js';
import { audit } from '../../../../common/audit/admin-audit.js';
import { withQuotaTransaction } from '../../../commerce/index.js';

export const findDocument = (id: string) => prisma.knowledgeDocument.findFirst({ where: { id, active: true, indexedText: { not: null } } });
const changed = () => new AppError(409, 'KNOWLEDGE_CHANGED', 'Tài liệu đã thay đổi hoặc lượt index đã hết hạn. Hãy lập chỉ mục lại.');

export async function beginIndex(documentId: string, version: Date) {
  return withQuotaTransaction(async (tx) => {
    if (!await tx.knowledgeDocument.findFirst({ where: { id: documentId, active: true, indexedText: { not: null }, updatedAt: version } })) throw changed();
    const index = await tx.aiKnowledgeIndex.upsert({ where: { documentId }, create: { documentId }, update: {} });
    if (index.busyUntil && index.busyUntil > new Date()) throw new AppError(409, 'AI_INDEX_BUSY', 'Tài liệu đang được lập chỉ mục.');
    const lease = randomUUID();
    await tx.aiKnowledgeIndex.update({ where: { documentId }, data: { lease, status: 'INDEXING', errorCode: null, busyUntil: new Date(Date.now() + 180_000) } });
    return lease;
  });
}

export async function publishIndex(actorId: string, documentId: string, version: Date, model: string, collection: string,
  lease: string, chunks: Array<{ id: string; text: string }>) {
  return withQuotaTransaction(async (tx) => {
    if (!await tx.knowledgeDocument.findFirst({ where: { id: documentId, active: true, indexedText: { not: null }, updatedAt: version } })) throw changed();
    const updated = await tx.aiKnowledgeIndex.updateMany({ where: { documentId, lease, busyUntil: { gt: new Date() } }, data: {
      status: 'READY', generation: lease, documentVersion: version, model, collection, indexedAt: new Date(), lease: null, busyUntil: null, errorCode: null,
    } });
    if (!updated.count) throw changed();
    // The delete trigger queues the old Qdrant point IDs in the same transaction.
    await tx.aiKnowledgeChunk.deleteMany({ where: { documentId } });
    await tx.aiKnowledgeChunk.createMany({ data: chunks.map((chunk, ordinal) => ({
      ...chunk, ordinal, documentId, documentVersion: version, model, collection, generation: lease,
    })) });
    await audit(tx, actorId, 'INDEX', 'KNOWLEDGE', documentId, `Qdrant: ${model}; ${chunks.length} chunks`);
    return { documentId, chunks: chunks.length, model, collection, generation: lease };
  });
}

export const failIndex = (documentId: string, lease: string, errorCode: string) => prisma.aiKnowledgeIndex.updateMany({
  where: { documentId, lease }, data: { status: 'FAILED', lease: null, busyUntil: null, errorCode },
});
export const indexStatus = (documentId: string) => prisma.aiKnowledgeIndex.findUnique({
  where: { documentId }, select: { status: true, model: true, collection: true, indexedAt: true, documentVersion: true, errorCode: true },
});

/** Qdrant chooses candidates; PostgreSQL remains the authority for text, version and visibility. */
export async function validChunks(ids: string[], model: string, collection: string) {
  const rows = await prisma.aiKnowledgeChunk.findMany({
    where: { id: { in: ids }, model, collection, document: { active: true, indexedText: { not: null } } },
    select: { id: true, documentId: true, documentVersion: true, text: true, document: { select: { title: true, updatedAt: true } } },
  });
  return rows.filter((row) => +row.documentVersion === +row.document.updatedAt);
}

export async function queueUnpublished(ids: string[], collection: string) {
  if (!ids.length) return;
  await withQuotaTransaction(async (tx) => {
    const live = new Set((await tx.aiKnowledgeChunk.findMany({ where: { id: { in: ids }, collection }, select: { id: true } })).map((row) => row.id));
    const obsolete = ids.filter((id) => !live.has(id));
    if (obsolete.length) await tx.aiVectorDeletion.createMany({ data: obsolete.map((pointId) => ({ pointId, collection })), skipDuplicates: true });
  });
}

export async function retireStale(collection: string) {
  await prisma.$executeRaw`DELETE FROM "AiKnowledgeChunk" AS c USING "KnowledgeDocument" AS d
    WHERE c."documentId" = d.id AND c.collection = ${collection}
    AND (NOT d.active OR d."indexedText" IS NULL OR c."documentVersion" <> d."updatedAt")`;
}
export const pendingDeletions = (collection: string) => prisma.aiVectorDeletion.findMany({ where: { collection }, orderBy: { createdAt: 'asc' }, take: 100 });
export const completeDeletions = (collection: string, ids: string[]) => prisma.aiVectorDeletion.deleteMany({ where: { collection, pointId: { in: ids } } });
export const remainingDeletions = (collection: string) => prisma.aiVectorDeletion.count({ where: { collection } });
