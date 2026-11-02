import { Prisma } from '@prisma/client';
import { publicLocation } from '../catalog/catalog.js';

/** Điều kiện tin được hiển thị công khai: đang bán và chủ tin còn hoạt động */
export const visible = { status: 'AVAILABLE' as const, owner: { status: 'ACTIVE' as const } };

/** Các cột của Listing trả về cho app */
export const fields = {
  id: true,
  title: true,
  description: true,
  price: true,
  isNegotiable: true,
  ownerId: true, categoryId: true, status: true, updatedAt: true,
  allowSale: true, allowExchange: true, exchangeWish: true, sellerType: true, attributes: true, location: true, reviewReason: true,
  condition: true,
  category: { select: { id: true, name: true } },
  images: true,
  createdAt: true,
  viewCount: true,
  publishedAt: true,
  owner: { select: { id: true, fullName: true, ratingAverage: true, ratingCount: true } },
} as const;

export type ListingRecord = Prisma.ListingGetPayload<{ select: typeof fields }>;

/**
 * Chuyển bản ghi Listing sang JSON cho app.
 * Người xem không phải chủ tin chỉ thấy vị trí tới mức phường (không lộ số nhà).
 * areaLabel: "Phường, Tỉnh" để hiện trên thẻ tin.
 */
export function output(listing: ListingRecord, owner = false) {
  const location = owner ? listing.location : publicLocation(listing.location);
  const address = listing.location as {province?:{name?:string};ward?:{name?:string}} | null;
  return { ...listing, price: listing.price.toString(), location,
    areaLabel: address ? [address.ward?.name,address.province?.name].filter(Boolean).join(', ') : '' };
}
