import type { Prisma } from '@prisma/client';
import type { DomainEvents } from '../../common/events/domain-events.js';
import type { ListingModeration } from '../listings/index.js';
import { pushToUsers } from './notification.push.js';
import * as repository from './notification.repository.js';
import { notify, notifyGrouped } from './notification.service.js';

/**
 * Mục 3: hoạt động giữa người dùng. Các loại không push (theo cột Push của tài liệu luồng) nằm trong IN_APP_ONLY_TYPES.
 * Hành động lặp lại nhiều (lưu tin, thích) được gộp vào một thông báo chưa đọc (notifyGrouped).
 */

const clip = (value: string, max: number) => (value.length > max ? `${value.slice(0, max - 1)}…` : value);
const vnd = (value: string) => `${Number(value).toLocaleString('vi-VN')} đ`;
/** Ngày theo giờ Việt Nam (YYYY-MM-DD), cho giới hạn mỗi ngày */
const vnDay = (date: Date) => new Date(date.getTime() + 7 * 3_600_000).toISOString().slice(0, 10);
/** Route bảng tin mở sẵn bình luận của bài */
const postLink = (postId: string) => `/feeds?post=${postId}`;
const others = (count: number) => (count > 1 ? ` và ${count - 1} người khác` : '');

/* ---------- 3.1 Tin khớp "Báo khi có hàng" ---------- */

export async function notifyWantedAlertMatched(event: DomainEvents['wantedAlert.matched'], tx?: Prisma.TransactionClient) {
  await notify(event.matches.map(({ userId, alertId, keywords }) => ({
    userId,
    type: 'WANTED_ALERT_MATCH' as const,
    title: 'Có tin mới khớp "Báo khi có hàng"',
    body: `Tin "${event.title}" khớp với "${keywords}".`,
    imageUrl: event.image,
    link: `/listings/${event.listingId}`,
    data: { listingId: event.listingId, listingTitle: event.title, alertId, alertKeywords: keywords },
    dedupeKey: `wanted:${event.listingId}`,
  })), tx);
}

/* ---------- 3.2 Tin nhắn chat: chỉ push ---------- */

export async function notifyChatMessage(event: DomainEvents['chat.messageSent']) {
  const [sender, recipients] = await Promise.all([
    repository.findActiveUser(event.senderId),
    repository.findChatRecipients(event.conversationId, event.senderId),
  ]);
  if (!sender || !recipients.length) return;
  const text = clip(event.text.replace(/\s+/g, ' ').trim(), 200);
  const now = new Date().toISOString();
  await pushToUsers(recipients.map(({ userId, unread }) => ({
    userId,
    message: {
      title: unread > 1 ? `${sender.fullName} (${unread} tin nhắn mới)` : sender.fullName,
      body: text,
      imageUrl: null,
      data: {
        kind: 'chat',
        notificationId: '',
        type: 'CHAT_MESSAGE',
        group: 'activity',
        link: `/messages/${event.conversationId}`,
        payload: JSON.stringify({ conversationId: event.conversationId, senderId: sender.id, senderName: sender.fullName,
          text, count: unread }),
        createdAt: now,
        unreadCount: '',
        // Tin mới thay thông báo cũ của cùng cuộc trò chuyện trên máy (không xếp chồng từng tin)
        tag: `chat:${event.conversationId}`,
      },
    },
  })));
}

/* ---------- 3.4 Có người theo dõi ---------- */

/** Theo dõi shop = theo dõi chủ shop: người có shop nhận lời báo theo tên shop */
export async function notifyUserFollowed(event: DomainEvents['user.followed']) {
  const [follower, shop] = await Promise.all([
    repository.findActiveUser(event.followerId),
    repository.findShopOfOwner(event.followingId),
  ]);
  if (!follower || event.followerId === event.followingId) return;
  await notify({
    userId: event.followingId,
    type: 'NEW_FOLLOWER',
    title: shop ? 'Có người theo dõi shop' : 'Có người theo dõi bạn',
    body: shop ? `${follower.fullName} vừa theo dõi shop ${shop.name}.` : `${follower.fullName} vừa theo dõi bạn.`,
    imageUrl: follower.avatarUrl,
    link: `/users/${follower.id}`,
    data: { userId: follower.id, userName: follower.fullName, ...(shop ? { shopId: shop.id, shopName: shop.name } : {}) },
    // Bỏ theo dõi rồi theo dõi lại không báo lần nữa
    dedupeKey: `follow:${follower.id}`,
  });
}

/* ---------- 3.5 Có người lưu tin (gộp) ---------- */

export async function notifyListingFavorited(event: DomainEvents['listing.favorited']) {
  const [user, listing] = await Promise.all([repository.findActiveUser(event.userId), repository.findListingBrief(event.listingId)]);
  if (!user || !listing || listing.ownerId === user.id) return;
  await notifyGrouped({
    userId: listing.ownerId,
    type: 'LISTING_FAVORITED',
    title: 'Tin của bạn được quan tâm',
    body: (count) => `${user.fullName}${others(count)} đã lưu tin "${listing.title}".`,
    imageUrl: listing.images[0] ?? null,
    link: `/listings/${listing.id}`,
    data: { listingId: listing.id, listingTitle: listing.title, userId: user.id, userName: user.fullName },
    groupKey: `fav:${listing.id}`,
    actorId: user.id,
  });
}

/* ---------- 3.6 Shop / người tôi theo dõi đăng tin mới ---------- */

/** Báo người theo dõi chủ tin, tối đa một lần mỗi ngày cho mỗi người bán */
async function notifyFollowersOfListing(listing: { listingId: string; ownerId: string; title: string; image: string | null },
  tx?: Prisma.TransactionClient) {
  const [followerIds, owner, shop] = await Promise.all([
    repository.findFollowerIds(listing.ownerId),
    repository.findActiveUser(listing.ownerId),
    repository.findShopOfOwner(listing.ownerId),
  ]);
  if (!followerIds.length || !owner) return;
  const name = shop?.name ?? owner.fullName;
  const day = vnDay(new Date());
  await notify(followerIds.map((userId) => ({
    userId,
    type: 'FOLLOWED_NEW_LISTING' as const,
    title: 'Có tin mới từ người bạn theo dõi',
    body: `${shop ? 'Shop ' : ''}${name} vừa đăng "${listing.title}".`,
    imageUrl: listing.image,
    link: `/listings/${listing.listingId}`,
    data: { listingId: listing.listingId, listingTitle: listing.title, userId: owner.id, userName: name, shop: !!shop },
    dedupeKey: `newlisting:${listing.ownerId}:${day}`,
  })), tx);
}

/** Tin hẹn ngày đăng vừa hiển thị */
export const notifyFollowersOnPublish = (event: DomainEvents['listing.published']) => notifyFollowersOfListing(event);

/* ---------- 3.7 Tin tôi đã lưu giảm giá / đã bán ---------- */

async function notifySaversOfPriceDrop(event: ListingModeration, tx: Prisma.TransactionClient) {
  const drop = event.priceDrop;
  if (!drop) return;
  const saverIds = await repository.findSaverIds(event.listingId, event.ownerId);
  await notify(saverIds.map((userId) => ({
    userId,
    type: 'SAVED_LISTING_PRICE_DROP' as const,
    title: 'Tin bạn lưu vừa giảm giá',
    body: `Tin "${event.title}" giảm từ ${vnd(drop.from)} còn ${vnd(drop.to)}.`,
    imageUrl: event.image,
    link: `/listings/${event.listingId}`,
    data: { listingId: event.listingId, listingTitle: event.title, oldPrice: drop.from, price: drop.to },
    dedupeKey: `pricedrop:${event.listingId}:${drop.to}`,
  })), tx);
}

export async function notifyListingSold(event: DomainEvents['listing.sold']) {
  const saverIds = await repository.findSaverIds(event.listingId, event.ownerId);
  await notify(saverIds.map((userId) => ({
    userId,
    type: 'SAVED_LISTING_SOLD' as const,
    title: event.exchanged ? 'Tin bạn lưu đã trao đổi' : 'Tin bạn lưu đã bán',
    body: `Tin "${event.title}" ${event.exchanged ? 'đã được trao đổi' : 'đã bán'}.`,
    imageUrl: event.image,
    link: `/listings/${event.listingId}`,
    data: { listingId: event.listingId, listingTitle: event.title, exchanged: event.exchanged },
    dedupeKey: `sold:${event.listingId}`,
  })));
}

/** Quyết định của admin: tin mới hiển thị (3.6), bản sửa làm giá giảm (3.7). Chạy trong transaction duyệt */
export async function notifyActivityOnModeration(tx: Prisma.TransactionClient, event: ListingModeration) {
  if (event.action !== 'APPROVE') return;
  if (event.edit) {
    await notifySaversOfPriceDrop(event, tx);
    return;
  }
  // Tin hẹn ngày đăng: báo khi job hiện tin
  if (!event.scheduled) await notifyFollowersOfListing(event, tx);
}

/* ---------- 3.8 Bảng tin ---------- */

const snippet = (text: string) => clip(text.replace(/\s+/g, ' ').trim(), 80);

export async function notifyPostLiked(event: DomainEvents['feed.postLiked']) {
  const [user, post] = await Promise.all([repository.findActiveUser(event.userId), repository.findPost(event.postId)]);
  if (!user || !post || post.authorId === user.id) return;
  await notifyGrouped({
    userId: post.authorId,
    type: 'FEED_POST_LIKED',
    title: 'Bài viết của bạn được thích',
    body: (count) => `${user.fullName}${others(count)} đã thích bài viết của bạn.`,
    imageUrl: post.imageUrl,
    link: postLink(post.id),
    data: { postId: post.id, postText: snippet(post.text), userId: user.id, userName: user.fullName },
    groupKey: `postlike:${post.id}`,
    actorId: user.id,
  });
}

export async function notifyCommentLiked(event: DomainEvents['feed.commentLiked']) {
  const [user, comment] = await Promise.all([repository.findActiveUser(event.userId), repository.findComment(event.commentId)]);
  if (!user || !comment || comment.authorId === user.id) return;
  await notifyGrouped({
    userId: comment.authorId,
    type: 'FEED_COMMENT_LIKED',
    title: 'Bình luận của bạn được thích',
    body: (count) => `${user.fullName}${others(count)} đã thích bình luận của bạn.`,
    link: postLink(comment.postId),
    data: { postId: comment.postId, commentId: comment.id, commentText: snippet(comment.text), userId: user.id,
      userName: user.fullName },
    groupKey: `commentlike:${comment.id}`,
    actorId: user.id,
  });
}

/** Bình luận bài → chủ bài (không push); trả lời bình luận → chủ bình luận (có push) */
export async function notifyFeedCommented(event: DomainEvents['feed.commented']) {
  const [user, post, parent] = await Promise.all([
    repository.findActiveUser(event.userId),
    repository.findPost(event.postId),
    event.parentId ? repository.findComment(event.parentId) : null,
  ]);
  if (!user || !post) return;
  const text = snippet(event.text);
  const data = { postId: post.id, commentId: event.commentId, commentText: text, userId: user.id, userName: user.fullName };
  const inputs = [];
  if (parent && parent.authorId !== user.id) {
    inputs.push({
      userId: parent.authorId,
      type: 'FEED_COMMENT_REPLIED' as const,
      title: 'Có người trả lời bình luận của bạn',
      body: `${user.fullName} đã trả lời: "${text}"`,
      imageUrl: user.avatarUrl,
      link: postLink(post.id),
      data,
      dedupeKey: `comment:${event.commentId}`,
    });
  }
  // Chủ bài đã nhận thông báo trả lời ở trên thì không báo thêm lần nữa
  if (post.authorId !== user.id && post.authorId !== parent?.authorId) {
    inputs.push({
      userId: post.authorId,
      type: 'FEED_POST_COMMENTED' as const,
      title: 'Bài viết của bạn có bình luận mới',
      body: `${user.fullName} đã bình luận: "${text}"`,
      imageUrl: user.avatarUrl,
      link: postLink(post.id),
      data,
      dedupeKey: `comment:${event.commentId}`,
    });
  }
  await notify(inputs);
}
