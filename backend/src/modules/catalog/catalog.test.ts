import assert from 'node:assert/strict';
import test from 'node:test';
import { PROVINCES, WARDS } from './catalog.data.js';
import { toCategoryDto } from './catalog.dto.js';
import { listWards, reverseGeocode } from './catalog.service.js';
import { listingLocation } from './catalog.validator.js';

test('every ward belongs to a known province and has a center', () => {
  for (const [code, wards] of Object.entries(WARDS)) {
    assert.ok(PROVINCES.some((unit) => unit.code === code), code);
    for (const ward of wards) {
      assert.equal(ward.parentCode, code);
      assert.ok(ward.center, ward.code);
    }
  }
});

test('listWards: 404 for unknown or inherited keys', () => {
  assert.ok(listWards(PROVINCES[0]!.code).length > 0);
  for (const code of ['00', 'constructor', '__proto__']) {
    assert.throws(() => listWards(code), { code: 'LOCATION_NOT_FOUND' });
  }
});

test('reverseGeocode finds the nearest ward within 30 km', () => {
  const ward = WARDS[PROVINCES[0]!.code]![0]!;
  assert.equal(reverseGeocode(ward.center!).ward.code, ward.code);
  assert.throws(() => reverseGeocode({ latitude: 0, longitude: 0 }), { code: 'LOCATION_NOT_FOUND' });
});

test('listingLocation falls back to the ward center', () => {
  const ward = WARDS[PROVINCES[0]!.code]![0]!;
  const location = listingLocation({ provinceCode: ward.parentCode, wardCode: ward.code });
  assert.equal(location?.latitude, ward.center!.latitude);
  assert.equal(location?.geoSource, 'ward_center');
});

test('toCategoryDto fills name, description, attributes for admin-created categories', () => {
  const dto = toCategoryDto({ id: 'x', name: 'X', active: true, metadata: {} });
  assert.deepEqual(dto, { id: 'x', name: 'X', description: '', attributes: [] });
});
