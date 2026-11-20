import { createHash } from 'node:crypto';
import type { ListingRecord } from '../../../listings/listing.dto.js';
import { normalizeKnowledge } from '../../../content/content.validator.js';

type SearchableListing = Pick<ListingRecord, 'title' | 'description' | 'price' | 'categoryId' | 'condition' | 'attributes'>;
export function listingText(listing: SearchableListing) {
  // Public search fields only: never include the location object or account fields.
  return JSON.stringify({ title: listing.title, description: listing.description, price: listing.price.toString(),
    categoryId: listing.categoryId, condition: listing.condition, attributes: listing.attributes });
}
export const listingHash = (listing: SearchableListing) => createHash('sha256').update(listingText(listing)).digest('hex');

export function matchesListingBrand(row: SearchableListing, requested?: string) {
  if (!requested) return true;
  const brand = normalizeKnowledge(requested).replace(/[^a-z0-9]+/g, ' ').trim();
  const attributes = row.attributes as Record<string, unknown>;
  const stored = normalizeKnowledge(String(attributes?.brand ?? '')).replace(/[^a-z0-9]+/g, ' ').trim();
  if (stored) return stored === brand;
  const title = ` ${normalizeKnowledge(row.title).replace(/[^a-z0-9]+/g, ' ')} `;
  return !!brand && title.includes(` ${brand} `);
}
