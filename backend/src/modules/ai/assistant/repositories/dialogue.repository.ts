import { prisma } from '../../../../lib/prisma.js';
import { z } from 'zod';
import { redactValue } from '../../../../common/security/redaction.js';

const metadata = z.object({ attributes: z.array(z.object({ key: z.string().max(60), label: z.object({ vi: z.string().max(100) }).optional() })).max(40).optional() });
export async function activeCategories() {
  const rows = await prisma.category.findMany({ where: { active: true }, select: { id: true, name: true, metadata: true }, orderBy: { id: 'asc' } });
  return redactValue(rows.map(row => ({ id: row.id, name: row.name, attributes: metadata.safeParse(row.metadata).data?.attributes ?? [] })));
}
