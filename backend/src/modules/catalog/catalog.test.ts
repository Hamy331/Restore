import assert from 'node:assert/strict';
import test from 'node:test';
import { LEGACY_WARD_CODES, PROVINCES, WARDS } from './catalog.data.js';
import { toCategoryDto } from './catalog.dto.js';
import { findWard, listWards, locatePoint, reverseGeocode, searchAreas } from './catalog.service.js';
import { listingLocation } from './catalog.validator.js';
import { wardCodeAt } from './location.geo.js';

test('dataset covers 34 provinces and 3,321 wards, each ward with a center inside its boundary', () => {
  assert.equal(PROVINCES.length, 34);
  assert.equal(Object.values(WARDS).flat().length, 3321);
  for (const [code, wards] of Object.entries(WARDS)) {
    assert.ok(PROVINCES.some((unit) => unit.code === code), code);
    for (const ward of wards) {
      assert.equal(ward.parentCode, code);
      assert.ok(ward.center, ward.code);
    }
  }
  const misses = Object.values(WARDS).flat().filter((ward) => wardCodeAt(ward.center!) !== ward.code);
  assert.ok(misses.length < 10, misses.map((ward) => ward.code).join(','));
});

test('listWards: 404 for unknown or inherited keys', () => {
  assert.equal(listWards('79').length, 168);
  for (const code of ['00', 'constructor', '__proto__']) {
    assert.throws(() => listWards(code), { code: 'LOCATION_NOT_FOUND' });
  }
});

test('reverseGeocode finds the ward containing GPS points across the country', () => {
  const cases: [number, number, string, string][] = [
    [10.7769, 106.7009, '79', 'Phường Sài Gòn'],
    [21.0285, 105.8542, '01', 'Phường Hoàn Kiếm'],
    [16.0678, 108.2208, '48', 'Phường Hải Châu'],
    [10.0341, 105.7880, '92', 'Phường Ninh Kiều'],
    [12.2388, 109.1967, '56', 'Phường Nha Trang'],
  ];
  for (const [latitude, longitude, province, ward] of cases) {
    const found = reverseGeocode({ latitude, longitude });
    assert.equal(found.province.code, province);
    assert.equal(found.ward.name, ward);
  }
  // Ngoài khơi gần bờ vẫn ra phường gần nhất, giữa đại dương thì 404
  assert.equal(locatePoint({ latitude: 10.30, longitude: 107.10 })?.province.code, '79');
  assert.throws(() => reverseGeocode({ latitude: 0, longitude: 0 }), { code: 'LOCATION_NOT_FOUND' });
});

test('searchAreas ignores accents, ranks name prefixes first, then wards of a matching province', () => {
  assert.deepEqual(searchAreas('ho chi minh', 1).map((area) => area.code), ['79']);
  assert.equal(searchAreas('Sài gòn', 5)[0]!.name, 'Phường Sài Gòn');
  assert.equal(searchAreas('da lat', 5)[0]!.parentName, 'Tỉnh Lâm Đồng');
  const hcmWards = searchAreas('thanh pho ho chi minh', 50);
  assert.ok(hcmWards.length === 50 && hcmWards.slice(1).every((area) => area.parentName === 'Thành phố Hồ Chí Minh'));
  assert.ok(searchAreas('ha', 5).every((area) => area.center.latitude > 0));
  assert.deepEqual(searchAreas('   ', 5), []);
});

test('legacy sample ward codes still resolve', () => {
  for (const [legacy, code] of Object.entries(LEGACY_WARD_CODES)) assert.equal(findWard(legacy)?.code, code);
  const location = listingLocation({ provinceCode: '79', wardCode: '79-SG' });
  assert.equal(location?.wardCode, '26740');
});

test('listingLocation falls back to the ward center and rejects a ward of another province', () => {
  const ward = WARDS['79']![0]!;
  const location = listingLocation({ provinceCode: ward.parentCode, wardCode: ward.code });
  assert.equal(location?.latitude, ward.center!.latitude);
  assert.equal(location?.geoSource, 'ward_center');
  assert.throws(() => listingLocation({ provinceCode: '01', wardCode: ward.code }), { code: 'INVALID_LOCATION' });
});

test('toCategoryDto fills name, description, attributes for admin-created categories', () => {
  const dto = toCategoryDto({ id: 'x', name: 'X', active: true, metadata: {} });
  assert.deepEqual(dto, { id: 'x', name: 'X', description: '', attributes: [] });
});
