import type { Prisma } from '@prisma/client';
import type { DomainEvents, ListingRef, PlanRef } from '../../common/events/domain-events.js';
import type { ListingModeration } from '../listings/index.js';
import { notify, NotificationInput } from './notification.service.js';
import type { NotificationType } from './notification.type.js';

/** Câu tiếng Việt dự phòng và route khi bấm, theo quyết định của admin */
function moderationNotice({ listingId, title, action, reason, edit, scheduled }: ListingModeration):
  Pick<NotificationInput, 'type' | 'title' | 'body' | 'link'> | null {
  const quoted = `"${title}"`;
  const why = reason ? ` Lý do: ${reason}` : '';
  const editPath = `/create-listing/edit/${listingId}`;
  const detailPath = `/listings/${listingId}`;
  const notice = (type: NotificationType, head: string, body: string, link: string) => ({ type, title: head, body, link });
  if (edit) {
    return action === 'APPROVE'
      ? notice('LISTING_EDIT_APPROVED', 'Bản sửa tin đã được duyệt', `Nội dung mới của tin ${quoted} đã được hiển thị.`, detailPath)
      : notice('LISTING_EDIT_REJECTED', 'Bản sửa tin chưa được duyệt', `Tin ${quoted} vẫn hiển thị nội dung cũ.${why}`, editPath);
  }
  switch (action) {
    case 'APPROVE':
      return scheduled
        ? notice('LISTING_APPROVED', 'Tin đã được duyệt', `Tin ${quoted} sẽ tự hiển thị vào ngày hẹn đăng.`, '/account')
        : notice('LISTING_APPROVED', 'Tin đã được duyệt', `Tin ${quoted} đã hiển thị với người mua.`, detailPath);
    case 'REJECT':
      return notice('LISTING_REJECTED', 'Tin bị từ chối', `Tin ${quoted} không được duyệt.${why}`, editPath);
    case 'REQUEST_CHANGES':
      return notice('LISTING_CHANGES_REQUESTED', 'Tin cần chỉnh sửa', `Sửa lại tin ${quoted} để được duyệt.${why}`, editPath);
    case 'REMOVE':
      return notice('LISTING_REMOVED', 'Tin đã bị gỡ', `Tin ${quoted} đã bị gỡ khỏi ReStore.${why}`, '/account');
    default:
      return null;
  }
}

/** Admin duyệt / từ chối / gỡ tin hoặc bản sửa → báo người bán (cùng transaction với quyết định) */
export async function notifyListingModerated(tx: Prisma.TransactionClient, event: ListingModeration) {
  const notice = moderationNotice(event);
  if (!notice) return;
  // 2.3: xu giữ khi gửi tin được hoàn thì báo luôn trong thông báo này, không gửi riêng
  const refunded = event.refunded ?? 0;
  await notify({
    ...notice,
    body: refunded > 0 ? `${notice.body} Đã hoàn ${refunded} Xu vào ví.` : notice.body,
    userId: event.ownerId,
    imageUrl: event.image,
    data: { listingId: event.listingId, listingTitle: event.title, reason: event.reason || null, scheduled: event.scheduled,
      ...(refunded > 0 && { refunded }) },
  }, tx);
}

/** data chung của thông báo về một tin */
const listingData = ({ listingId, title }: ListingRef) => ({ listingId, listingTitle: title });

/** 1.7 Tin hẹn ngày đăng tới ngày, đã tự hiển thị → báo người bán */
export async function notifyListingPublished(event: DomainEvents['listing.published']) {
  await notify({
    userId: event.ownerId,
    type: 'LISTING_PUBLISHED',
    title: 'Tin đã bắt đầu hiển thị',
    body: `Tin "${event.title}" tới ngày hẹn đăng và đã hiển thị với người mua.`,
    imageUrl: event.image,
    link: `/listings/${event.listingId}`,
    data: listingData(event),
  });
}

/** 1.8 Tin còn dưới 2 ngày hiển thị → nhắc người bán gia hạn, mỗi lần hết hạn một lần */
export async function notifyListingExpiring(event: DomainEvents['listing.expiring']) {
  await notify({
    userId: event.ownerId,
    type: 'LISTING_EXPIRING',
    title: 'Tin sắp hết hạn',
    body: `Tin "${event.title}" còn ${event.daysLeft} ngày hiển thị. Gia hạn để tiếp tục bán.`,
    imageUrl: event.image,
    link: '/account',
    data: { ...listingData(event), days: event.daysLeft, expiresAt: event.expiresAt.toISOString() },
    dedupeKey: `expiring:${event.listingId}:${event.expiresAt.toISOString()}`,
  });
}

/** 1.9 Tin hết thời gian hiển thị, đã ẩn → báo người bán gia hạn */
export async function notifyListingExpired(event: DomainEvents['listing.expired']) {
  await notify({
    userId: event.ownerId,
    type: 'LISTING_EXPIRED',
    title: 'Tin đã hết hạn',
    body: `Tin "${event.title}" đã hết thời gian hiển thị. Gia hạn để tiếp tục bán.`,
    imageUrl: event.image,
    link: '/account',
    data: listingData(event),
    dedupeKey: `expired:${event.listingId}:${event.expiresAt.toISOString()}`,
  });
}

/** 1.10 Job tự gia hạn thành công → báo số xu đã trừ */
export async function notifyListingAutoExtended(event: DomainEvents['listing.autoExtended']) {
  await notify({
    userId: event.ownerId,
    type: 'LISTING_AUTO_EXTENDED',
    title: 'Tin đã được tự gia hạn',
    body: `Tin "${event.title}" được gia hạn thêm ${event.days} ngày, trừ ${event.credits} Xu.`,
    imageUrl: event.image,
    link: '/credits/history',
    data: { ...listingData(event), days: event.days, amount: event.credits },
  });
}

/** 1.10 Tự gia hạn thất bại vì thiếu xu → nhắc nạp (mỗi lần hết hạn một lần, job thử lại mỗi 10 phút) */
export async function notifyListingAutoExtendFailed(event: DomainEvents['listing.autoExtendFailed']) {
  await notify({
    userId: event.ownerId,
    type: 'LISTING_AUTO_EXTEND_FAILED',
    title: 'Không đủ Xu để tự gia hạn',
    body: `Tin "${event.title}" sắp hết hạn nhưng ví không đủ Xu để tự gia hạn. Nạp thêm Xu để giữ tin hiển thị.`,
    imageUrl: event.image,
    link: '/credits/topup',
    data: listingData(event),
    dedupeKey: `autoextend-fail:${event.listingId}:${event.expiresAt.toISOString()}`,
  });
}

/* ---------- 2. Ví Xu, đẩy tin, gói ---------- */

/** 2.1 Nạp Xu thành công → báo số xu đã nhận (kèm xu tặng) */
export async function notifyTopupPaid(event: DomainEvents['credit.topupPaid']) {
  const bonus = event.bonus > 0 ? ` (tặng thêm ${event.bonus} Xu)` : '';
  await notify({
    userId: event.userId,
    type: 'CREDIT_TOPUP_SUCCESS',
    title: 'Nạp Xu thành công',
    body: `Bạn đã nhận ${event.credits} Xu${bonus}.`,
    link: '/credits/history',
    data: { amount: event.credits, bonus: event.bonus, topupCode: event.code },
    dedupeKey: `topup-paid:${event.orderId}`,
  });
}

/** 2.2 Đơn nạp thất bại / hết hạn → báo xu không đổi */
export async function notifyTopupFailed(event: DomainEvents['credit.topupFailed']) {
  await notify({
    userId: event.userId,
    type: 'CREDIT_TOPUP_FAILED',
    title: 'Nạp Xu không thành công',
    body: `Đơn nạp ${event.code} chưa được thanh toán. Xu của bạn không thay đổi.`,
    link: '/credits/topup',
    data: { topupCode: event.code, status: event.status },
    dedupeKey: `topup-failed:${event.orderId}`,
  });
}

/** 2.4 Xu tặng sắp hết hạn → nhắc dùng (mỗi mốc hết hạn một lần) */
export async function notifyBonusExpiring(event: DomainEvents['credit.bonusExpiring']) {
  await notify({
    userId: event.userId,
    type: 'CREDIT_BONUS_EXPIRING',
    title: 'Xu tặng sắp hết hạn',
    body: `${event.amount} Xu tặng sẽ hết hạn sau ${event.daysLeft} ngày.`,
    link: '/credits',
    data: { amount: event.amount, days: event.daysLeft, expiresAt: event.expiresAt.toISOString() },
    dedupeKey: `bonus-expiring:${event.expiresAt.toISOString()}`,
  });
}

const promotionData = (event: DomainEvents['promotion.started']) =>
  ({ ...listingData(event), kind: event.kind, days: event.days, endsAt: event.endsAt.toISOString() });

/** 2.5 Tin bắt đầu được đẩy / lên Hot sale */
export async function notifyPromotionStarted(event: DomainEvents['promotion.started']) {
  const featured = event.kind === 'FEATURED';
  await notify({
    userId: event.ownerId,
    type: 'BOOST_STARTED',
    title: featured ? 'Tin đã lên Hot sale' : 'Tin đang được đẩy',
    body: featured
      ? `Tin "${event.title}" nằm trong mục Hot sale ${event.days} ngày.`
      : `Tin "${event.title}" được đẩy lên đầu trong ${event.days} ngày.`,
    imageUrl: event.image,
    link: `/listings/${event.listingId}`,
    data: promotionData(event),
    dedupeKey: `promo-started:${event.promotionId}`,
  });
}

/** 2.6 Hết thời gian đẩy tin / Hot sale → mời đẩy tiếp */
export async function notifyPromotionEnded(event: DomainEvents['promotion.ended']) {
  const featured = event.kind === 'FEATURED';
  await notify({
    userId: event.ownerId,
    type: 'BOOST_ENDED',
    title: featured ? 'Tin đã hết thời gian Hot sale' : 'Đã hết thời gian đẩy tin',
    body: featured ? `Tin "${event.title}" đã rời mục Hot sale.` : `Tin "${event.title}" đã hết thời gian đẩy.`,
    imageUrl: event.image,
    link: `/boost/${event.listingId}`,
    data: promotionData(event),
    dedupeKey: `promo-ended:${event.promotionId}`,
  });
}

/** 2.7 Admin từ chối đơn mua gói / đẩy tin → báo kèm lý do */
export async function notifyOrderRejected(event: DomainEvents['order.rejected']) {
  const what = event.kind === 'STORE_ORDER'
    ? `Đơn mua gói ${event.packageName}`
    : `Đơn ${event.packageName} cho tin "${event.listingTitle ?? ''}"`;
  await notify({
    userId: event.userId,
    type: 'ORDER_REJECTED',
    title: 'Đơn bị từ chối',
    body: `${what} không được xác nhận. Lý do: ${event.reason}`,
    link: event.kind === 'STORE_ORDER' ? '/plans' : '/boost',
    data: { orderKind: event.kind, packageName: event.packageName, listingId: event.listingId,
      listingTitle: event.listingTitle, reason: event.reason },
    dedupeKey: `order-rejected:${event.orderId}`,
  });
}

const planData = (event: PlanRef) => ({ packageId: event.packageId, planName: event.planName, endsAt: event.endsAt.toISOString() });
const viDate = (date: Date) => date.toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });

/** 2.8 Mua / gia hạn / nâng cấp gói cửa hàng xong */
export async function notifyPlanActivated(event: DomainEvents['plan.activated']) {
  await notify({
    userId: event.userId,
    type: 'STORE_PLAN_ACTIVATED',
    title: 'Gói đã kích hoạt',
    body: `Gói ${event.planName} đã kích hoạt, dùng đến ngày ${viDate(event.endsAt)}.`,
    link: '/plans',
    data: { ...planData(event), mode: event.mode },
  });
}

/** 2.9 Gói cửa hàng còn dưới 3 ngày → nhắc gia hạn (mỗi mốc hết hạn một lần) */
export async function notifyPlanExpiring(event: DomainEvents['plan.expiring']) {
  await notify({
    userId: event.userId,
    type: 'STORE_PLAN_EXPIRING',
    title: 'Gói sắp hết hạn',
    body: `Gói ${event.planName} hết hạn ngày ${viDate(event.endsAt)}. Gia hạn để giữ hạn mức đăng tin.`,
    link: '/plans',
    data: { ...planData(event), days: event.daysLeft },
    dedupeKey: `plan-expiring:${event.endsAt.toISOString()}`,
  });
}

/** 2.9 Gói cửa hàng đã hết hạn → về gói Cá nhân */
export async function notifyPlanExpired(event: DomainEvents['plan.expired']) {
  await notify({
    userId: event.userId,
    type: 'STORE_PLAN_EXPIRED',
    title: 'Gói đã hết hạn',
    body: `Gói ${event.planName} đã hết hạn, tài khoản chuyển về gói Cá nhân. Gia hạn để dùng lại hạn mức của gói.`,
    link: '/plans',
    data: planData(event),
    dedupeKey: `plan-expired:${event.endsAt.toISOString()}`,
  });
}

/** Câu tiếng Việt của lý do từ chối poster (khớp REJECT_REASONS) */
const POSTER_REASONS: Record<string, string> = {
  WRONG_SIZE: 'Sai kích thước ảnh',
  MISLEADING_PRICE: 'Giá hoặc ưu đãi gây hiểu lầm',
  BRAND_MISUSE: 'Dùng logo, thương hiệu không thuộc shop',
  PROHIBITED: 'Nội dung bị cấm',
  TOO_MUCH_TEXT: 'Quá nhiều chữ trên ảnh',
  OTHER: 'Lý do khác',
};

/** Admin duyệt / từ chối cửa hàng; bấm vào mở trang Quản lý shop */
export async function notifyShopReviewed(event: DomainEvents['shop.reviewed']) {
  await notify({
    userId: event.ownerId,
    type: event.approved ? 'SHOP_APPROVED' : 'SHOP_REJECTED',
    title: event.approved ? 'Cửa hàng đã được duyệt' : 'Cửa hàng chưa được duyệt',
    body: event.approved
      ? `Cửa hàng "${event.shopName}" đã được duyệt, người mua đã xem được trang shop.`
      : `Cửa hàng "${event.shopName}" chưa được duyệt. Lý do: ${(event.note ?? '').replace(/[.\s]+$/, '')}. Sửa thông tin rồi lưu để gửi duyệt lại.`,
    link: '/my-shop',
    data: { shopId: event.shopId, shopName: event.shopName, reason: event.note },
  });
}

/** 2.10 Admin duyệt / từ chối poster của shop */
export async function notifyPosterReviewed(event: DomainEvents['poster.reviewed']) {
  const reason = event.reason ? [POSTER_REASONS[event.reason] ?? event.reason, event.note].filter(Boolean).join(': ') : null;
  await notify({
    userId: event.ownerId,
    type: event.approved ? 'SHOP_POSTER_APPROVED' : 'SHOP_POSTER_REJECTED',
    title: event.approved ? 'Poster đã được duyệt' : 'Poster bị từ chối',
    body: event.approved
      ? `Poster "${event.title}" đã được duyệt và sẽ lên trang chủ theo lịch chạy.`
      : `Poster "${event.title}" không được duyệt.${reason ? ` Lý do: ${reason}` : ''}`,
    imageUrl: event.imageUrl,
    link: '/shop-posters',
    data: { posterId: event.posterId, posterTitle: event.title, reasonCode: event.reason, note: event.note },
  });
}
