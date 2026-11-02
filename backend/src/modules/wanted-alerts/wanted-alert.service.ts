import { Prisma } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import type { ListingLocation } from '../catalog/index.js';
import {
  AlertIdParams, DraftInput, MatchesQuery, PreviewQuery, toMatchDto, toPreviewMatchDto, toWantedAlertDto, WantedAlertRecord,
} from './wanted-alert.dto.js';
import { MatchableAlert, MatchableListing, matchListing } from './wanted-alert.matcher.js';
import * as wantedAlertRepository from './wanted-alert.repository.js';
import { MAX_ALERTS_PER_USER, PREVIEW_CANDIDATES } from './wanted-alert.type.js';

const notFound = () => new AppError(404, 'WANTED_ALERT_NOT_FOUND', 'Không tìm thấy thông báo.');

type OwnedAlert = WantedAlertRecord & { matches: { listing: { images: string[] } }[] };

/** Gắn số tin khớp và ảnh bìa vào từng thông báo */
async function withStats(alerts: OwnedAlert[]) {
  const counts = await wantedAlertRepository.countMatches(alerts.map((alert) => alert.id));
  return alerts.map(({ matches, ...alert }) => toWantedAlertDto(alert, {
    matchCount: counts.get(alert.id)?.matchCount ?? 0,
    newMatchCount: counts.get(alert.id)?.newMatchCount ?? 0,
    previewImages: matches.flatMap((match) => match.listing.images.slice(0, 1)),
  }));
}

async function findOwnedOrThrow(userId: string, id: string) {
  const alert = await wantedAlertRepository.findOwned(userId, id);
  if (!alert) throw notFound();
  return alert;
}

/** Danh mục phải còn dùng */
async function assertCategory(categoryId: string | null) {
  if (categoryId && !(await wantedAlertRepository.findActiveCategory(categoryId))) {
    throw new AppError(400, 'INVALID_INPUT', 'Danh mục không tồn tại hoặc đã ngừng sử dụng.', 'categoryId');
  }
}

/** Dạng MatchableAlert của bản nháp/thông báo để chấm điểm */
const toMatchable = (alert: Omit<DraftInput, 'areaLabel'> | Pick<WantedAlertRecord, 'keywords' | 'categoryId' | 'conditions' |
  'dealTypes' | 'areaCode' | 'areaLevel' | 'matchLevel' | 'minPrice' | 'maxPrice'>, createdAt: Date): MatchableAlert => ({
  keywords: alert.keywords,
  matchLevel: alert.matchLevel,
  categoryId: alert.categoryId,
  minPrice: alert.minPrice == null ? null : Number(alert.minPrice),
  maxPrice: alert.maxPrice == null ? null : Number(alert.maxPrice),
  conditions: alert.conditions,
  dealTypes: alert.dealTypes,
  areaCode: alert.areaCode,
  areaLevel: alert.areaLevel === 'ward' ? 'ward' : alert.areaLevel === 'province' ? 'province' : null,
  createdAt,
});

/** Dạng MatchableListing của một tin; [createdAt] là mốc so với lúc tạo thông báo */
const toMatchableListing = (listing: {
  title: string; description: string; price: Prisma.Decimal; condition: string | null; allowSale: boolean; allowExchange: boolean;
  categoryId: string | null; location: Prisma.JsonValue;
}, createdAt: Date): MatchableListing => {
  const location = listing.location as Partial<ListingLocation> | null;
  return {
    title: listing.title,
    description: listing.description,
    price: Number(listing.price),
    condition: listing.condition ?? '',
    allowSale: listing.allowSale,
    allowExchange: listing.allowExchange,
    categoryId: listing.categoryId,
    provinceCode: location?.provinceCode ?? null,
    wardCode: location?.wardCode ?? null,
    createdAt,
  };
};

/* ---------- API ---------- */

export async function listAlerts(userId: string) {
  return withStats(await wantedAlertRepository.findAllOwned(userId));
}

export async function getAlert(userId: string, { id }: AlertIdParams) {
  const [alert] = await withStats([await findOwnedOrThrow(userId, id)]);
  return alert;
}

/** Tạo thông báo; chỉ tin được duyệt sau lúc này mới được tính là khớp */
export async function createAlert(userId: string, draft: DraftInput) {
  await assertCategory(draft.categoryId);
  if (await wantedAlertRepository.countByUser(userId) >= MAX_ALERTS_PER_USER) {
    throw new AppError(409, 'WANTED_ALERT_LIMIT', `Bạn chỉ có thể tạo tối đa ${MAX_ALERTS_PER_USER} thông báo.`);
  }
  const now = new Date();
  const alert = await wantedAlertRepository.create({ ...draft, userId, seenAt: now, createdAt: now });
  return toWantedAlertDto(alert);
}

export async function deleteAlert(userId: string, { id }: AlertIdParams) {
  const { count } = await wantedAlertRepository.deleteOwned(userId, id);
  if (!count) throw notFound();
}

/** Đã mở xem tin khớp: các tin khớp trước lúc này không còn là tin mới */
export async function markSeen(userId: string, { id }: AlertIdParams) {
  const { count } = await wantedAlertRepository.markSeen(userId, id, new Date());
  if (!count) throw notFound();
}

/**
 * Tin hiện có gần giống bản nháp, điểm cao nhất trước (chấm trên tối đa PREVIEW_CANDIDATES tin mới nhất
 * qua bộ lọc). Không ghi gì vào DB.
 */
export async function preview(userId: string, draft: DraftInput, { limit }: PreviewQuery) {
  await assertCategory(draft.categoryId);
  const alert = toMatchable(draft, new Date(0));
  const listings = await wantedAlertRepository.findPreviewCandidates(draft, userId, PREVIEW_CANDIDATES);
  const scored = listings.flatMap((listing) => {
    const score = matchListing(alert, toMatchableListing(listing, listing.publishedAt ?? listing.createdAt));
    return score == null ? [] : [{ listing, score }];
  });
  // Ổn định: cùng điểm thì giữ thứ tự mới đăng trước của câu truy vấn
  const top = scored.sort((a, b) => b.score - a.score).slice(0, limit);
  const favorites = await wantedAlertRepository.findFavoriteIds(userId, top.map((item) => item.listing.id));
  return top.map(({ listing, score }) => toPreviewMatchDto(listing, score, favorites.has(listing.id)));
}

/** Tin đã khớp của thông báo, khớp gần nhất trước */
export async function listMatches(userId: string, { id }: AlertIdParams, { page, limit, skip }: MatchesQuery) {
  const alert = await findOwnedOrThrow(userId, id);
  const [matches, totalItems] = await wantedAlertRepository.findMatchesPage(alert.id, limit, skip);
  const favorites = await wantedAlertRepository.findFavoriteIds(userId, matches.map((match) => match.listing.id));
  return {
    items: matches.map((match) => toMatchDto(match, alert.seenAt, favorites.has(match.listing.id))),
    page: { page, limit, totalItems },
  };
}

/* ---------- Khi admin duyệt tin ---------- */

/**
 * Chấm điểm tin vừa được duyệt với mọi thông báo của người khác và ghi các cặp khớp.
 * Chạy trong transaction duyệt tin (đăng ký qua onListingApproved trong index.ts).
 */
export async function matchApprovedListing(tx: Prisma.TransactionClient, listingId: string, approvedAt: Date) {
  const listing = await wantedAlertRepository.findListingForMatching(tx, listingId);
  if (!listing) return;
  const matchable = toMatchableListing(listing, approvedAt);
  const alerts = await wantedAlertRepository.findCandidateAlerts(tx, listing);
  const matches = alerts.flatMap((alert) => {
    const score = matchListing(toMatchable(alert, alert.createdAt), matchable);
    return score == null ? [] : [{ alertId: alert.id, score }];
  });
  await wantedAlertRepository.saveMatches(tx, listing.id, matches, approvedAt);
}
