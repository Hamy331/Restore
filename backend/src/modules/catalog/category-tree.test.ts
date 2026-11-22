import assert from 'node:assert/strict';
import test from 'node:test';
import { attributeFilterQuery, validateAttributes } from '../listings/listing.validator.js';
import { toCategoryDto } from './catalog.dto.js';
import { effectiveMetadata, findSubcategory, subcategoriesOf } from './category-tree.js';

// Danh mục mẫu theo đúng cấu trúc prisma/seed/categories.ts (seed được kiểm tra riêng ở test/categories-seed.test.ts)
const select = (key: string, values: string[], extra = {}) => ({ key, type: 'select', options: values.map((value) => ({ value })), ...extra });
const electronics = {
  hasCondition: true,
  attributes: [select('warranty', ['none', 'store'], { filter: 'multi' })],
  subcategories: [
    { id: 'dien-thoai', attributes: [select('brand', ['Apple', 'Samsung'], { required: true, filter: 'multi' }),
      { key: 'model', type: 'text' }, select('storage', ['128 GB'], { filter: 'multi' })] },
    { id: 'laptop', attributes: [select('cpu', ['Apple M2']), { key: 'year', type: 'number', min: 2000, max: 2030, filter: 'range' }] },
    { id: 'phu-kien', attributes: [], hasCondition: false },
  ],
};
const keys = (metadata: { attributes?: { key: string }[] }) => (metadata.attributes ?? []).map((item) => item.key);

test('effectiveMetadata: gộp thuộc tính cha + con, id lạ thì giữ metadata cha', () => {
  assert.deepEqual(subcategoriesOf(electronics).map((item) => item.id), ['dien-thoai', 'laptop', 'phu-kien']);
  assert.deepEqual(keys(effectiveMetadata(electronics, 'dien-thoai')), ['warranty', 'brand', 'model', 'storage']);
  assert.deepEqual(keys(effectiveMetadata(electronics, 'khong-co')), ['warranty']);
  assert.equal(findSubcategory(electronics, null), undefined);
  assert.deepEqual(subcategoriesOf({}), []);
});

test('effectiveMetadata: hasCondition của con ghi đè cha', () => {
  assert.equal(effectiveMetadata(electronics, 'phu-kien').hasCondition, false);
  assert.equal(effectiveMetadata(electronics, 'laptop').hasCondition, true);
});

test('validateAttributes theo danh mục con: thiếu hãng bắt buộc thì lỗi, key của con khác thì lỗi', () => {
  const phone = effectiveMetadata(electronics, 'dien-thoai');
  assert.doesNotThrow(() => validateAttributes({ brand: 'Apple', model: 'iPhone 13', storage: '128 GB' }, phone, true));
  assert.throws(() => validateAttributes({ model: 'iPhone 13' }, phone, true), /brand/);
  assert.throws(() => validateAttributes({ brand: 'Apple', cpu: 'Apple M2' }, phone, true), /cpu/);
});

test('toCategoryDto: có subcategoryId thì trả thuộc tính đã gộp và subcategory', () => {
  const dto = toCategoryDto({ id: 'electronics', name: 'Điện tử', active: true, metadata: electronics }, 'laptop') as Record<string, unknown>;
  assert.deepEqual(keys(dto as never), ['warranty', 'cpu', 'year']);
  assert.deepEqual(dto.subcategory, { id: 'laptop', name: undefined });
  assert.equal(dto.subcategories, undefined);
  const plain = toCategoryDto({ id: 'electronics', name: 'Điện tử', active: true, metadata: electronics }) as Record<string, unknown>;
  assert.deepEqual(keys(plain as never), ['warranty']);
  assert.equal(plain.subcategory, undefined);
});

test('attributeFilterQuery: nhận danh sách giá trị và khoảng số, từ chối dữ liệu sai', () => {
  assert.deepEqual(attributeFilterQuery(undefined), []);
  assert.deepEqual(attributeFilterQuery('{"brand":["Apple","Apple","Samsung"],"year":{"min":2015},"color":[]}'), [
    { key: 'brand', values: ['Apple', 'Samsung'] }, { key: 'year', min: 2015 },
  ]);
  for (const bad of ['nope', '[]', '{"Brand":["x"]}', '{"year":{"min":5,"max":1}}', '{"year":{"min":"1"}}', '{"brand":[1]}']) {
    assert.throws(() => attributeFilterQuery(bad), /thuộc tính/, bad);
  }
});
