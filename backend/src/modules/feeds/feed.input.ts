import { AppError } from '../../common/errors/app-error.js';
export const id = (v: unknown): string => {
  if (typeof v !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v)) throw new AppError(400, 'INVALID_ID', 'Invalid ID');
  return v;
};
export function page(q: Record<string, unknown>) {
  const limit = q.limit === undefined ? 20 : Number(q.limit);
  if (!Number.isInteger(limit) || limit < 1 || limit > 50) throw new AppError(400, 'INVALID_LIMIT', 'Limit must be 1–50');
  let after: { createdAt: Date; id: string } | undefined;
  if (q.cursor !== undefined) {
    try {
      if (typeof q.cursor !== 'string' || q.cursor.length > 300) throw Error();
      const c = JSON.parse(Buffer.from(q.cursor, 'base64url').toString());
      after = { id: id(c.id), createdAt: new Date(c.createdAt) };
      if (!Number.isFinite(after.createdAt.getTime())) throw Error();
    } catch { throw new AppError(400, 'INVALID_CURSOR', 'Invalid cursor'); }
  }
  return { limit, after };
}
export function input(body: unknown, comment = false) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) throw new AppError(422, 'INVALID_BODY', 'Invalid body');
  const b = body as Record<string, unknown>;
  if (Object.keys(b).some(k => !(comment ? ['text'] : ['text', 'imageUrl', 'listingId']).includes(k))) throw new AppError(422, 'INVALID_FIELDS', 'Unexpected fields');
  const text = b.text ?? '';
  if (typeof text !== 'string' || text.length > 2000 || (comment && !text.trim())) throw new AppError(422, 'INVALID_TEXT', 'Text must contain at most 2000 characters');
  const imageUrl = b.imageUrl ?? null;
  if (imageUrl !== null && (typeof imageUrl !== 'string' || imageUrl.length > 2000 || !imageUrl.startsWith(`https://res.cloudinary.com/${process.env.CLOUDINARY_CLOUD_NAME}/image/upload/`))) throw new AppError(422, 'INVALID_IMAGE', 'Invalid uploaded image');
  if (!text.trim() && !imageUrl) throw new AppError(422, 'EMPTY_POST', 'Text or image required');
  return { text: text.trim(), imageUrl: imageUrl as string | null, listingId: b.listingId == null ? null : id(b.listingId) };
}
