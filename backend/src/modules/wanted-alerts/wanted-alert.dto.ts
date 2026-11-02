import { Prisma } from '@prisma/client';
import type { z } from 'zod';
import { ListingRecord, toFeedItemDto } from '../listings/index.js';
import type { alertIdParams, draftBody, matchesQuery, previewQuery } from './wanted-alert.validator.js';

/* ---------- Vào (suy ra từ schema) ---------- */

export type DraftInput = z.output<typeof draftBody>;
export type PreviewQuery = z.output<typeof previewQuery>;
export type MatchesQuery = z.output<typeof matchesQuery>;
export type AlertIdParams = z.output<typeof alertIdParams>;

/* ---------- Ra ---------- */

/** Cột của WantedAlert đọc từ DB, kèm tên danh mục */
export const wantedAlertSelect = {
  id: true, userId: true, keywords: true, categoryId: true, minPrice: true, maxPrice: true, conditions: true, dealTypes: true,
  areaCode: true, areaLevel: true, areaLabel: true, matchLevel: true, seenAt: true, lastMatchedAt: true, createdAt: true, updatedAt: true,
  category: { select: { id: true, name: true } },
} as const satisfies Prisma.WantedAlertSelect;

export type WantedAlertRecord = Prisma.WantedAlertGetPayload<{ select: typeof wantedAlertSelect }>;

export type AlertStats = { matchCount: number; newMatchCount: number; previewImages: string[] };

const toNumber = (value: bigint | null) => (value == null ? null : Number(value));

/**
 * Thông báo cho app (WantedAlertItem.fromJson):
 * { id, userId, keywords, categoryId, category { id, name } | null, minPrice, maxPrice, conditions[], dealTypes[],
 *   area { code, level, label } | null, areaLabel, matchLevel, seenAt, lastMatchedAt, createdAt, updatedAt,
 *   matchCount, newMatchCount, previewImages[] }
 */
export function toWantedAlertDto(alert: WantedAlertRecord, stats: AlertStats = { matchCount: 0, newMatchCount: 0, previewImages: [] }) {
  const { areaCode, areaLevel, areaLabel, minPrice, maxPrice, ...rest } = alert;
  return {
    ...rest,
    minPrice: toNumber(minPrice),
    maxPrice: toNumber(maxPrice),
    area: areaCode ? { code: areaCode, level: areaLevel, label: areaLabel } : null,
    areaLabel,
    ...stats,
  };
}

export type WantedAlertDto = ReturnType<typeof toWantedAlertDto>;

/** Điểm giống làm tròn 4 chữ số để trả về */
export const roundScore = (score: number) => Math.round(score * 10_000) / 10_000;

/** Tin gợi ý khi soạn thông báo: thẻ tin (như trang chủ) + score */
export const toPreviewMatchDto = (listing: ListingRecord, score: number, isFavorite: boolean) =>
  ({ ...toFeedItemDto(listing, { distanceKm: null, isFeatured: false, isFavorite }), score: roundScore(score) });

/** Tin đã khớp: thẻ tin + score, matchedAt, isNew (khớp sau lần xem cuối) */
export const toMatchDto = (
  match: { listing: ListingRecord; score: number; matchedAt: Date },
  seenAt: Date,
  isFavorite: boolean,
) => ({
  ...toPreviewMatchDto(match.listing, match.score, isFavorite),
  matchedAt: match.matchedAt,
  isNew: match.matchedAt > seenAt,
});
