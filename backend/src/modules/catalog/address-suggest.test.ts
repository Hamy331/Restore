import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import { clearAddressSuggestCache, suggestAddresses } from './address-suggest.service.js';

const realFetch = globalThis.fetch;
let calls: URL[] = [];

function stubFetch(body: unknown, status = 200) {
  globalThis.fetch = (async (input: string | URL | Request) => {
    calls.push(new URL(String(input)));
    return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
  }) as typeof fetch;
}

const feature = (properties: Record<string, unknown>, lon: number, lat: number) =>
  ({ type: 'Feature', geometry: { type: 'Point', coordinates: [lon, lat] }, properties: { countrycode: 'VN', ...properties } });

afterEach(() => {
  globalThis.fetch = realFetch;
  calls = [];
  clearAddressSuggestCache();
  delete process.env.ADDRESS_PROVIDER;
});

test('photon: street lines with our ward/province, filtered to the chosen province, cached', async () => {
  stubFetch({
    features: [
      feature({ housenumber: '12', street: 'Nguyễn Huệ', osm_key: 'place' }, 106.7035, 10.7745),
      feature({ name: 'Nguyễn Huệ', osm_key: 'highway', type: 'street' }, 106.7032, 10.7740),
      feature({ name: 'Nguyễn Huệ', osm_key: 'highway', type: 'street' }, 107.5860, 16.4637), // Huế
      feature({ name: 'Nguyen Hue', countrycode: 'LA' }, 102.6, 17.9),
    ],
  });
  const input = { q: 'nguyen hue', provinceCode: '79', limit: 6 };
  const result = await suggestAddresses(input);
  assert.deepEqual(result.map((item) => item.label), ['12 Nguyễn Huệ', 'Nguyễn Huệ']);
  assert.equal(result[0]!.provinceCode, '79');
  assert.match(result[0]!.description, /Thành phố Hồ Chí Minh$/);
  assert.equal(calls[0]!.searchParams.get('q'), 'nguyen hue');
  assert.ok(calls[0]!.searchParams.get('lat'));
  await suggestAddresses(input);
  assert.equal(calls.length, 1);
});

test('off returns nothing without calling out', async () => {
  process.env.ADDRESS_PROVIDER = 'off';
  stubFetch({ features: [] });
  assert.deepEqual(await suggestAddresses({ q: 'abc', limit: 5 }), []);
  assert.equal(calls.length, 0);
});

test('provider errors become 502 ADDRESS_SUGGEST_UNAVAILABLE', async () => {
  stubFetch({ message: 'busy' }, 503);
  await assert.rejects(suggestAddresses({ q: 'le loi', limit: 5 }), { code: 'ADDRESS_SUGGEST_UNAVAILABLE' });
  process.env.ADDRESS_PROVIDER = 'goong';
  await assert.rejects(suggestAddresses({ q: 'le loi', limit: 5 }), { code: 'ADDRESS_PROVIDER_INVALID' });
});
