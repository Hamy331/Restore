/**
 * Danh mục 2 cấp: danh mục cha là dòng Category, danh mục con nằm trong metadata.subcategories.
 * Thuộc tính hiệu lực của tin = thuộc tính chung của cha + thuộc tính của con; thuộc tính có `filter`
 * (single / multi / list cho select, range cho number) là bộ lọc của danh mục con đó.
 */

export type CategoryAttribute = {
  key: string;
  type: string;
  required?: boolean;
  /** Kiểu bộ lọc: single / multi / list (chọn giá trị) hoặc range (khoảng số) */
  filter?: 'single' | 'multi' | 'list' | 'range';
  min?: number;
  max?: number;
  maxLength?: number;
  options?: Array<{ value: string }>;
};

export type Subcategory = { id: string; name?: unknown; attributes?: CategoryAttribute[]; hasCondition?: boolean };

type CategoryMetadata = { attributes?: CategoryAttribute[]; subcategories?: Subcategory[]; hasCondition?: boolean };

const asMetadata = (metadata: unknown): CategoryMetadata =>
  metadata && typeof metadata === 'object' ? (metadata as CategoryMetadata) : {};

/** Danh mục con của danh mục cha (rỗng nếu danh mục chưa chia con) */
export const subcategoriesOf = (metadata: unknown): Subcategory[] => {
  const list = asMetadata(metadata).subcategories;
  return Array.isArray(list) ? list : [];
};

export const findSubcategory = (metadata: unknown, subcategoryId: string | null | undefined) =>
  subcategoryId ? subcategoriesOf(metadata).find((item) => item.id === subcategoryId) : undefined;

/**
 * Xác định danh mục con của tin: [child] là danh mục con hợp lệ (undefined nếu id lạ / không chọn),
 * [required] true khi danh mục cha có chia con (tin phải chọn một), [metadata] là metadata hiệu lực.
 * Đăng tin, sửa nháp, duyệt tin và DTO chi tiết tin cùng dùng hàm này.
 */
export function resolveSubcategory(metadata: unknown, subcategoryId: string | null | undefined) {
  const child = findSubcategory(metadata, subcategoryId);
  return { child, required: subcategoriesOf(metadata).length > 0, metadata: effectiveMetadata(metadata, child?.id) };
}

/**
 * Metadata hiệu lực cho một danh mục con: attributes gộp (cha trước, con sau; con ghi đè key trùng),
 * hasCondition của con nếu có. Không có con (hoặc id lạ) thì trả metadata cha như cũ.
 */
export function effectiveMetadata(metadata: unknown, subcategoryId: string | null | undefined): CategoryMetadata {
  const parent = asMetadata(metadata);
  const child = findSubcategory(metadata, subcategoryId);
  if (!child) return parent;
  const own = child.attributes ?? [];
  const keys = new Set(own.map((attribute) => attribute.key));
  return {
    ...parent,
    attributes: [...(parent.attributes ?? []).filter((attribute) => !keys.has(attribute.key)), ...own],
    hasCondition: child.hasCondition ?? parent.hasCondition,
  };
}
