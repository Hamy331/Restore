import type { Category } from '@prisma/client';
import type { ListingLocation } from './catalog.validator.js';

/**
 * Danh mục cho app: metadata (tên vi/en, mô tả, icon, thuộc tính) cộng id, name, description, attributes
 * luôn có mặt (danh mục admin mới tạo chưa có đủ metadata).
 */
export function toCategoryDto(category: Category) {
  const metadata = category.metadata as Record<string, unknown>;
  return {
    ...metadata, id: category.id, name: metadata.name ?? category.name,
    description: metadata.description ?? '', attributes: metadata.attributes ?? [],
  };
}

/** Địa chỉ công khai của tin: chỉ tỉnh, phường và tâm phường, không lộ địa chỉ đường hay GPS thật */
export function publicLocation(value: unknown) {
  if (!value || typeof value !== 'object') return null;
  const location = value as ListingLocation;
  return {
    provinceCode: location.provinceCode, wardCode: location.wardCode,
    province: location.province, ward: location.ward, ...location.ward.center, geoSource: 'ward_center',
  };
}
