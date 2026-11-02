import assert from 'node:assert/strict';
import test from 'node:test';
import { AppError } from '../../../common/errors/app-error.js';
import { parse } from '../../../common/validation/schemas.js';
import { feedQuery, recommendedQuery } from './feed.validation.js';

const parseFeedQuery = (query: unknown) => parse(feedQuery, query);
const parseRecommendedQuery = (query: unknown) => parse(recommendedQuery, query);

test('feed query defaults to newest page 1 with 10 items', () => {
  const query = parseFeedQuery({});
  assert.equal(query.filter, 'newest');
  assert.deepEqual(query.pagination, { page: 1, limit: 10, skip: 0 });
  assert.equal(query.filters.nearby, undefined);
});

test('feed query accepts limit and the legacy pageSize name', () => {
  assert.deepEqual(parseFeedQuery({ page: '3', limit: '10' }).pagination, { page: 3, limit: 10, skip: 20 });
  assert.equal(parseFeedQuery({ pageSize: '12' }).pagination.limit, 12);
  assert.throws(() => parseFeedQuery({ limit: '500' }), AppError);
  assert.throws(() => parseFeedQuery({ page: '0' }), AppError);
});

test('feed filters map to listing filters', () => {
  assert.throws(() => parseFeedQuery({ filter: 'nearby' }), AppError);
  const nearby = parseFeedQuery({ filter: 'nearby', latitude: '10.77', longitude: '106.7' });
  assert.deepEqual(nearby.filters.nearby, { latitude: 10.77, longitude: 106.7, radius: 5 });
  assert.equal(parseFeedQuery({ filter: 'exchange' }).filters.allowExchange, true);
  assert.equal(parseFeedQuery({ latitude: '10.77', longitude: '106.7' }).filters.nearby, undefined);
  assert.throws(() => parseFeedQuery({ filter: 'popular' }), AppError);
});

test('recommended limit is between 1 and 20', () => {
  assert.equal(parseRecommendedQuery({}).limit, 10);
  assert.equal(parseRecommendedQuery({ limit: '5' }).limit, 5);
  assert.throws(() => parseRecommendedQuery({ limit: '21' }), AppError);
});
