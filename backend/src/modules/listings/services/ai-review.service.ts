import { createHash } from 'node:crypto';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { contentTypeOf, getObject } from '../../../services/storage.service.js';
import type { GeminiProvider } from '../../ai/assistant/services/gemini.provider.js';
import { AI_MAX_IMAGES, inspectListing } from '../ai-inspection.js';
import { IMAGE_NAME, IMAGE_PREFIX } from '../listing.type.js';

/*
 * AI xem ảnh và nội dung tin / bản sửa đang chờ duyệt, lưu kết quả vào aiReview để admin tham khảo.
 * hash = md5 của tiêu đề, mô tả và ảnh lúc xem: nội dung đổi thì kết quả cũ không còn hiện và được xem lại.
 */

/** Kết quả lưu ở Listing.aiReview / ListingRevision.aiReview */
type StoredReview = { hash: string; verdict: 'OK' | 'SUSPECT' | 'UNKNOWN'; reason: string; checkedAt: string };
/** Kết quả trả cho trang quản trị: OK, SUSPECT (nghi hàng cấm, kèm lý do), UNKNOWN (AI không trả lời được) */
export type AiReview = Omit<StoredReview, 'hash'>;

/** Ảnh gửi AI không quá ngần này byte tổng cộng (giới hạn yêu cầu của Gemini là 20 MB sau base64) */
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;

/** Cùng công thức với md5(...) trong SQL bên dưới */
const contentHash = ({ title, description, images }: { title: string; description: string; images: string[] }) =>
  createHash('md5').update(`${title}\n${description}\n${images.join(' ')}`).digest('hex');

/** Kết quả AI cho admin; null khi chưa xem hoặc nội dung đã đổi từ lúc xem (đang chờ xem lại) */
export function aiReviewFor(row: { title: string; description: string; images: string[]; aiReview?: Prisma.JsonValue }): AiReview | null {
  const review = row.aiReview as StoredReview | null | undefined;
  if (!review || review.hash !== contentHash(row)) return null;
  const { hash: _hash, ...rest } = review;
  return rest;
}

/** Ảnh đầu của tin đọc được từ storage, tối đa AI_MAX_IMAGES ảnh và MAX_IMAGE_BYTES */
async function readImages(urls: string[]) {
  const images: { mimeType: string; data: Buffer }[] = [];
  let total = 0;
  for (const url of urls) {
    const name = url.slice(IMAGE_PREFIX.length);
    if (images.length >= AI_MAX_IMAGES || !url.startsWith(IMAGE_PREFIX) || !IMAGE_NAME.test(name)) continue;
    const data = await getObject('listings', name).catch(() => null);
    if (!data || total + data.length > MAX_IMAGE_BYTES) continue;
    total += data.length;
    images.push({ mimeType: contentTypeOf(name), data });
  }
  return images;
}

type Pending = { id: string; kind: 'LISTING' | 'REVISION'; title: string; description: string; images: string[]; category: string | null; hash: string };

/**
 * Xem [batch] tin / bản sửa chờ duyệt chưa có kết quả (hoặc đã đổi nội dung), gửi sớm trước; trả về số mục đã xem.
 * Lỗi nhà cung cấp (hạn mức, mạng) ném ra để dừng lượt này, lượt sau thử lại.
 */
export async function reviewPendingListings(provider: GeminiProvider, batch = 5) {
  const rows = await prisma.$queryRaw<Pending[]>`
    SELECT id, kind, title, description, images, category, hash FROM (
      SELECT l.id, 'LISTING' AS kind, l.title, l.description, l.images, c.name AS category, l."updatedAt" AS since,
        md5(l.title || chr(10) || l.description || chr(10) || array_to_string(l.images, ' ')) AS hash, l."aiReview" AS review
      FROM "Listing" l LEFT JOIN "Category" c ON c.id = l."categoryId"
      WHERE l.status = 'PENDING'
      UNION ALL
      SELECT r."listingId", 'REVISION', r.title, r.description, r.images, c.name, r."submittedAt",
        md5(r.title || chr(10) || r.description || chr(10) || array_to_string(r.images, ' ')), r."aiReview"
      FROM "ListingRevision" r JOIN "Listing" l ON l.id = r."listingId" LEFT JOIN "Category" c ON c.id = l."categoryId"
      WHERE r.status = 'PENDING'
    ) pending
    WHERE review IS NULL OR review->>'hash' IS DISTINCT FROM hash
    ORDER BY since LIMIT ${batch}`;
  for (const row of rows) {
    const result = await inspectListing(provider, await readImages(row.images),
      { category: row.category, title: row.title, description: row.description }, AbortSignal.timeout(60_000));
    const review: StoredReview = {
      hash: row.hash, verdict: !result ? 'UNKNOWN' : result.prohibited ? 'SUSPECT' : 'OK',
      reason: result?.reason ?? '', checkedAt: new Date().toISOString(),
    };
    // SQL thô để không đổi updatedAt: admin dùng updatedAt để biết tin có bị sửa từ lúc mở không
    if (row.kind === 'LISTING') {
      await prisma.$executeRaw`UPDATE "Listing" SET "aiReview" = ${JSON.stringify(review)}::jsonb WHERE id = ${row.id}`;
    } else {
      await prisma.$executeRaw`UPDATE "ListingRevision" SET "aiReview" = ${JSON.stringify(review)}::jsonb WHERE "listingId" = ${row.id}`;
    }
  }
  return rows.length;
}
