import type { Category } from '@prisma/client';
import { resolveSubcategory } from './category-tree.js';
import type { ListingLocation } from './catalog.validator.js';

/**
 * Danh mục cho app: metadata (tên vi/en, mô tả, icon, thuộc tính chung, subcategories) cộng id, name, description,
 * attributes, subcategories luôn có mặt (danh mục admin mới tạo chưa có đủ metadata).
 * Có [subcategoryId] (trang chi tiết tin): attributes và hasCondition là bản đã gộp của danh mục con đó,
 * kèm subcategory { id, name } và không kèm danh sách subcategories (app không cần ở trang này).
 */
export function toCategoryDto(category: Pick<Category, 'id' | 'name' | 'active' | 'metadata'>, subcategoryId?: string | null) {
  const { subcategories, ...metadata } = category.metadata as Record<string, unknown>;
  const { child, metadata: effective } = resolveSubcategory(category.metadata, subcategoryId);
  return {
    ...metadata, id: category.id, name: metadata.name ?? category.name,
    description: metadata.description ?? '', attributes: effective.attributes ?? [],
    ...(child ? { subcategory: { id: child.id, name: child.name } } : { subcategories: subcategories ?? [] }),
    ...(effective.hasCondition !== undefined && { hasCondition: effective.hasCondition }),
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
