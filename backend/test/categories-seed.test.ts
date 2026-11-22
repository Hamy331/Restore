// Kiểm tra seed danh mục 2 cấp và hàm chuyển tin của danh mục cũ.
//   node --import tsx --test test/categories-seed.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { CATEGORIES } from '../prisma/seed/categories.js';
import { DEMO_LISTINGS } from '../prisma/seed/demo.js';
import { DEMO_PENDING_LISTINGS } from '../prisma/seed/demo-wanted-alerts.js';
import { mapLegacyListing } from '../prisma/seed/legacy-categories.js';
import { PRO_SELLERS, SHOPS } from '../prisma/seed/shops.js';
import { CATEGORY_ORDER } from '../src/modules/catalog/catalog.type.js';
import { effectiveMetadata, subcategoriesOf } from '../src/modules/catalog/category-tree.js';
import { validateAttributes } from '../src/modules/listings/listing.validator.js';

test('seed: 9 danh mục cha đúng thứ tự, mỗi cha có danh mục con, id con không trùng', () => {
  assert.deepEqual(CATEGORIES.map((item) => item.id), CATEGORY_ORDER);
  const all = CATEGORIES.flatMap((category) => subcategoriesOf(category).map((item) => item.id));
  assert.equal(new Set(all).size, all.length);
  for (const category of CATEGORIES) assert.ok(subcategoriesOf(category).length > 0, category.id);
});

test('seed: thuộc tính có filter phải là select (single/multi/list) hoặc number (range), danh mục có priceMax', () => {
  for (const category of CATEGORIES) {
    for (const child of subcategoriesOf(category)) {
      for (const attribute of effectiveMetadata(category, child.id).attributes ?? []) {
        if (attribute.filter && attribute.filter !== 'range') assert.equal(attribute.type, 'select', `${child.id}.${attribute.key}`);
        if (attribute.key === 'warranty') assert.equal(attribute.filter, undefined, 'warranty lọc qua nhóm tình trạng');
        if (attribute.filter === 'range') assert.equal(attribute.type, 'number', `${child.id}.${attribute.key}`);
      }
      assert.ok((child as { priceMax?: number }).priceMax! > 0, child.id);
    }
    assert.ok((category as { priceMax?: number }).priceMax! > 0, category.id);
  }
});

test('mapLegacyListing: tin cũ sang danh mục con mới, đổi thuộc tính và bỏ key không còn dùng', () => {
  const phone = mapLegacyListing({ categoryId: 'phones', title: 'iPhone 13 128GB', attributes: { brand: 'apple', model: 'iPhone 13', storage: '128 GB' } });
  assert.deepEqual([phone.categoryId, phone.subcategoryId, phone.attributes.brand], ['electronics', 'dien-thoai', 'Apple']);
  const bike = mapLegacyListing({ categoryId: 'vehicles', title: 'Honda Vision 2022',
    attributes: { vehicle_type: 'motorbike', brand: 'Honda', model: 'Vision', engine_cc: 110 } });
  assert.deepEqual([bike.subcategoryId, bike.attributes.bike_type, bike.attributes.engine_size], ['xe-may', 'scooter', '100_175']);
  assert.equal(bike.attributes.vehicle_type, undefined);
  const dog = mapLegacyListing({ categoryId: 'pets', title: 'Corgi 3 tháng', attributes: { pet_type: 'dog', breed: 'Corgi', age_months: 2 } });
  assert.deepEqual([dog.subcategoryId, dog.attributes.breed, dog.attributes.age_group], ['cho', 'corgi', 'young']);
  const stationery = mapLegacyListing({ categoryId: 'books', title: 'Bút gel', attributes: { genre: 'stationery' } });
  assert.deepEqual([stationery.categoryId, stationery.subcategoryId], ['office', 'do-dung-van-phong']);
});

test('mọi tin mẫu (demo, shop) chuyển xong đều hợp lệ với danh mục con mới', () => {
  const samples = [...DEMO_LISTINGS, ...DEMO_PENDING_LISTINGS, ...SHOPS.flatMap((shop) => shop.listings),
    ...PRO_SELLERS.flatMap((seller) => seller.listings)];
  for (const item of samples) {
    const mapped = mapLegacyListing(item);
    const category = CATEGORIES.find((entry) => entry.id === mapped.categoryId)!;
    assert.doesNotThrow(() => validateAttributes(mapped.attributes as never, effectiveMetadata(category, mapped.subcategoryId), true), item.title);
  }
});
