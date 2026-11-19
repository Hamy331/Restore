import { audit } from '../../common/audit/admin-audit.js';
import { AppError } from '../../common/errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { storePackageForUser, utcMonthStart } from '../commerce/index.js';
import { isMediaUrl } from '../media/media.service.js';
import * as posterRepository from './poster.repository.js';
import type { AdminPosterRecord, PosterRecord } from './poster.repository.js';
import { cooldownUntil, DAY, POSTER_RULES, posterState } from './poster.rules.js';
import type { AdminPosterQuery, PosterCreateBody, PosterRejectBody, PosterUpdateBody } from './poster.validator.js';

type Db = Parameters<Parameters<typeof prisma.$transaction>[0]>[0];

/**
 * Poster shop cho app: { id, title, imageUrl, status, state, startsAt, endsAt, days,
 *   listing { id, title, image } | null, rejectReason, rejectNote, reviewedAt, createdAt, updatedAt }
 */
export function toPosterDto(poster: PosterRecord, now: Date) {
  const { listing, shopId: _shopId, ...rest } = poster;
  const days = poster.startsAt && poster.endsAt ? Math.round((poster.endsAt.getTime() - poster.startsAt.getTime()) / DAY) : null;
  return {
    ...rest, state: posterState(poster, now), days,
    listing: listing ? { id: listing.id, title: listing.title, image: listing.images[0] ?? null, available: listing.status === 'AVAILABLE' } : null,
  };
}

/** Gói, shop, lượt đã dùng và hạn khóa của chủ shop */
async function quota(db: Db, userId: string, now: Date) {
  const [shop, plan] = await Promise.all([posterRepository.findOwnShop(db, userId), storePackageForUser(db, userId, now)]);
  const limits = { activeLimit: plan.package.posterActiveLimit, monthlyLimit: plan.package.posterMonthlyLimit };
  if (!shop) return { shop, plan, limits, usedThisMonth: 0, slotsInUse: 0, cooldownUntil: null };
  const [usedThisMonth, slotsInUse, rejections] = await Promise.all([
    posterRepository.countCreatedSince(db, shop.id, utcMonthStart(now)),
    posterRepository.countHoldingSlots(db, shop.id, now),
    posterRepository.findRejectionTimes(db, shop.id, new Date(now.getTime() - POSTER_RULES.rejectWindowDays * DAY)),
  ]);
  return { shop, plan, limits, usedThisMonth, slotsInUse, cooldownUntil: cooldownUntil(rejections, now) };
}

/**
 * Trang quản lý poster: { shop { id, name, logoUrl, verified } | null, plan { tier, endsAt },
 *   limits { activeLimit, monthlyLimit, usedThisMonth, slotsInUse, minDays, maxDays, maxLeadDays, cooldownUntil },
 *   posters [50 poster mới nhất] }
 */
export async function getMyPosters(userId: string, now = new Date()) {
  const q = await quota(prisma, userId, now);
  const posters = q.shop ? await posterRepository.findPosters(prisma, q.shop.id) : [];
  return {
    shop: q.shop ? { id: q.shop.id, name: q.shop.name, logoUrl: q.shop.logoUrl, verified: q.shop.verificationType !== null } : null,
    plan: { tier: q.plan.package.tier, endsAt: q.plan.endsAt },
    limits: {
      ...q.limits, usedThisMonth: q.usedThisMonth, slotsInUse: q.slotsInUse,
      minDays: POSTER_RULES.minDays, maxDays: POSTER_RULES.maxDays, maxLeadDays: POSTER_RULES.maxLeadDays,
      cooldownUntil: q.cooldownUntil,
    },
    posters: posters.map((poster) => toPosterDto(poster, now)),
  };
}

/** Kiểm tra quyền gửi: có shop, gói còn cho đăng poster, không bị khóa */
function assertCanSubmit(q: Awaited<ReturnType<typeof quota>>) {
  if (!q.shop) throw new AppError(409, 'SHOP_REQUIRED', 'Bạn cần có trang shop để đăng poster.');
  if (q.limits.activeLimit <= 0) {
    throw new AppError(403, 'POSTER_PLAN_REQUIRED', 'Chỉ gói Cửa hàng mới đăng được poster.', undefined, { tier: q.plan.package.tier });
  }
  if (q.cooldownUntil) {
    throw new AppError(409, 'POSTER_COOLDOWN', 'Poster bị từ chối nhiều lần, tạm khóa gửi poster.', undefined,
      { until: q.cooldownUntil.toISOString() });
  }
  return q.shop;
}

/** Khung chạy [startsAt, endsAt): bắt đầu sớm nhất là bây giờ, muộn nhất sau 14 ngày */
function window(startsAt: Date | null | undefined, days: number, now: Date) {
  const start = !startsAt || startsAt < now ? now : startsAt;
  if (start.getTime() > now.getTime() + POSTER_RULES.maxLeadDays * DAY) {
    throw new AppError(400, 'POSTER_START_TOO_LATE', `Chỉ hẹn ngày bắt đầu trước tối đa ${POSTER_RULES.maxLeadDays} ngày.`, 'startsAt');
  }
  return { startsAt: start, endsAt: new Date(start.getTime() + days * DAY) };
}

function assertOwnImage(userId: string, imageUrl: string) {
  if (!isMediaUrl(imageUrl, 'poster') || !imageUrl.includes(`/posters/${userId}_`)) {
    throw new AppError(400, 'INVALID_IMAGE_URL', 'Ảnh poster phải được tải lên qua /media/images?purpose=poster.', 'imageUrl');
  }
}

async function assertListing(db: Db, userId: string, listingId: string | null | undefined) {
  if (!listingId) return;
  if (!(await posterRepository.findOwnAvailableListing(db, userId, listingId))) {
    throw new AppError(400, 'POSTER_LISTING_INVALID', 'Chỉ gắn được tin đang bán của shop.', 'listingId');
  }
}

async function assertSlot(db: Db, shopId: string, activeLimit: number, from: Date, to: Date, exceptId?: string) {
  if (await posterRepository.countOverlapping(db, shopId, from, to, exceptId) >= activeLimit) {
    throw new AppError(409, 'POSTER_SLOT_FULL', `Gói của bạn chạy tối đa ${activeLimit} poster cùng lúc.`, undefined, { activeLimit });
  }
}

/** Gửi poster mới, vào trạng thái chờ duyệt. Lỗi: SHOP_REQUIRED, POSTER_PLAN_REQUIRED, POSTER_COOLDOWN,
 *  POSTER_MONTHLY_LIMIT, POSTER_SLOT_FULL, POSTER_START_TOO_LATE, INVALID_IMAGE_URL, POSTER_LISTING_INVALID */
export async function createPoster(userId: string, body: PosterCreateBody, now = new Date()) {
  assertOwnImage(userId, body.imageUrl);
  return prisma.$transaction(async (tx) => {
    const shop = await posterRepository.findOwnShop(tx, userId);
    if (shop) await posterRepository.lockShop(tx, shop.id);
    const q = await quota(tx, userId, now);
    const { id: shopId } = assertCanSubmit(q);
    if (q.usedThisMonth >= q.limits.monthlyLimit) {
      throw new AppError(409, 'POSTER_MONTHLY_LIMIT', `Mỗi tháng gửi tối đa ${q.limits.monthlyLimit} poster.`, undefined,
        { monthlyLimit: q.limits.monthlyLimit });
    }
    const range = window(body.startsAt, body.days, now);
    await assertListing(tx, userId, body.listingId);
    await assertSlot(tx, shopId, q.limits.activeLimit, range.startsAt, range.endsAt);
    const poster = await posterRepository.createPoster(tx, {
      shopId, title: body.title, imageUrl: body.imageUrl, listingId: body.listingId ?? null, ...range, status: 'PENDING',
    });
    return toPosterDto(poster, now);
  });
}

/**
 * Sửa poster chờ duyệt, bị từ chối, hoặc đã duyệt mà chưa kết thúc. Sau khi sửa poster quay về chờ duyệt
 * (không tính thêm lượt gửi trong tháng). Lỗi thêm: 404 POSTER_NOT_FOUND, 409 POSTER_NOT_EDITABLE
 */
export async function updatePoster(userId: string, id: string, body: PosterUpdateBody, now = new Date()) {
  if (body.imageUrl !== undefined) assertOwnImage(userId, body.imageUrl);
  return prisma.$transaction(async (tx) => {
    const shop = await posterRepository.findOwnShop(tx, userId);
    if (shop) await posterRepository.lockShop(tx, shop.id);
    const q = await quota(tx, userId, now);
    const { id: shopId } = assertCanSubmit(q);
    const poster = await posterRepository.findPoster(tx, shopId, id);
    if (!poster) throw new AppError(404, 'POSTER_NOT_FOUND', 'Không tìm thấy poster.');
    const state = posterState(poster, now);
    if (!['PENDING', 'SCHEDULED', 'RUNNING', 'REJECTED'].includes(state)) {
      throw new AppError(409, 'POSTER_NOT_EDITABLE', 'Poster đã kết thúc hoặc đã dừng, hãy tạo poster mới.');
    }
    const oldDays = poster.startsAt && poster.endsAt ? Math.round((poster.endsAt.getTime() - poster.startsAt.getTime()) / DAY) : POSTER_RULES.minDays;
    // Không gửi startsAt thì giữ ngày cũ (đã qua thì tính từ bây giờ); gửi null = chạy ngay khi được duyệt
    const start = body.startsAt === undefined ? poster.startsAt : body.startsAt;
    const range = window(start, body.days ?? oldDays, now);
    await assertListing(tx, userId, body.listingId);
    await assertSlot(tx, shopId, q.limits.activeLimit, range.startsAt, range.endsAt, id);
    const updated = await posterRepository.updatePoster(tx, id, {
      ...(body.title !== undefined ? { title: body.title } : {}),
      ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
      ...(body.listingId !== undefined ? { listingId: body.listingId } : {}),
      ...range, status: 'PENDING', rejectReason: null, rejectNote: null, reviewedAt: null, reviewedById: null,
    });
    return toPosterDto(updated, now);
  });
}

/** Shop dừng poster đang chạy / đã lên lịch, hoặc hủy poster chờ duyệt. Lỗi 409 POSTER_NOT_STOPPABLE */
export async function stopPoster(userId: string, id: string, now = new Date()) {
  return prisma.$transaction(async (tx) => {
    const shop = await posterRepository.findOwnShop(tx, userId);
    const poster = shop ? await posterRepository.findPoster(tx, shop.id, id) : null;
    if (!poster) throw new AppError(404, 'POSTER_NOT_FOUND', 'Không tìm thấy poster.');
    const state = posterState(poster, now);
    if (!['PENDING', 'SCHEDULED', 'RUNNING'].includes(state)) {
      throw new AppError(409, 'POSTER_NOT_STOPPABLE', 'Poster này không còn chạy.');
    }
    const updated = await posterRepository.updatePoster(tx, id, {
      status: 'STOPPED', ...(state === 'RUNNING' ? { endsAt: now } : {}),
    });
    return toPosterDto(updated, now);
  });
}

/* ---------- admin ---------- */

/** Poster cho trang duyệt: poster + shop { id, name, logoUrl, accentColor, verified, ownerEmail, ownerName, planTier, planEndsAt } */
function toAdminPosterDto(poster: AdminPosterRecord, now: Date) {
  const { shop, reviewedById, ...rest } = poster;
  const subscription = shop.owner.storeSubscription;
  return {
    ...toPosterDto(rest, now), reviewedById,
    shop: {
      id: shop.id, name: shop.name, logoUrl: shop.logoUrl, accentColor: shop.accentColor, verified: shop.verificationType !== null,
      ownerId: shop.ownerId, ownerEmail: shop.owner.email, ownerName: shop.owner.fullName,
      planTier: subscription && subscription.endsAt > now ? subscription.package.tier : 'PERSONAL',
      planEndsAt: subscription?.endsAt ?? null,
    },
  };
}

/** Danh sách cho admin, kèm số poster đang chờ duyệt: { pendingCount, items } */
export async function adminListPosters(query: AdminPosterQuery, now = new Date()) {
  const [items, pendingCount] = await Promise.all([
    posterRepository.findPostersForAdmin(query.status === 'ALL' ? undefined : query.status),
    posterRepository.countPending(),
  ]);
  return { pendingCount, items: items.map((poster) => toAdminPosterDto(poster, now)) };
}

async function decide(adminId: string, id: string, now: Date, decision: { status: 'APPROVED' } | { status: 'REJECTED'; body: PosterRejectBody }) {
  return prisma.$transaction(async (tx) => {
    const poster = await posterRepository.findPosterForAdmin(tx, id);
    if (!poster) throw new AppError(404, 'POSTER_NOT_FOUND', 'Không tìm thấy poster.');
    if (poster.status !== 'PENDING') throw new AppError(409, 'POSTER_NOT_PENDING', 'Poster không còn ở trạng thái chờ duyệt.');
    if (decision.status === 'APPROVED' && poster.endsAt && poster.endsAt <= now) {
      throw new AppError(409, 'POSTER_EXPIRED', 'Poster đã qua ngày kết thúc, không duyệt được nữa.');
    }
    const reject = decision.status === 'REJECTED' ? decision.body : null;
    await tx.shopBanner.update({
      where: { id },
      data: {
        status: decision.status, reviewedAt: now, reviewedById: adminId,
        rejectReason: reject?.reason ?? null, rejectNote: reject?.note ?? null,
      },
    });
    await audit(tx, adminId, decision.status === 'APPROVED' ? 'SHOP_POSTER_APPROVE' : 'SHOP_POSTER_REJECT', 'ShopBanner', id,
      reject ? `${reject.reason}${reject.note ? `: ${reject.note}` : ''}` : 'approve',
      { status: poster.status }, { status: decision.status, rejectReason: reject?.reason ?? null });
    return toAdminPosterDto((await posterRepository.findPosterForAdmin(tx, id))!, now);
  });
}

/** Duyệt poster. Lỗi 404 POSTER_NOT_FOUND, 409 POSTER_NOT_PENDING, 409 POSTER_EXPIRED */
export const approvePoster = (adminId: string, id: string, now = new Date()) =>
  decide(adminId, id, now, { status: 'APPROVED' });

/** Từ chối poster kèm lý do; lý do OTHER cần ghi chú (400 REJECT_NOTE_REQUIRED) */
export function rejectPoster(adminId: string, id: string, body: PosterRejectBody, now = new Date()) {
  if (body.reason === 'OTHER' && !body.note) throw new AppError(400, 'REJECT_NOTE_REQUIRED', 'Hãy ghi lý do từ chối.', 'note');
  return decide(adminId, id, now, { status: 'REJECTED', body });
}
