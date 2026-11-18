import type { Prisma } from '@prisma/client';
import type { DomainEvents, ListingRef } from '../../common/events/domain-events.js';
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
  await notify({
    ...notice,
    userId: event.ownerId,
    imageUrl: event.image,
    data: { listingId: event.listingId, listingTitle: event.title, reason: event.reason || null, scheduled: event.scheduled },
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
