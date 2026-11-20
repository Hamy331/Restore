import assert from 'node:assert/strict';
import { test } from 'node:test';
import { randomUUID } from 'node:crypto';
import { QdrantStore, qdrantConfig } from './qdrant.repository.js';
import { lexicalVector, LEXICAL_VECTOR } from '../services/lexical.service.js';

const config = { endpoint: 'https://test.us-west-1-0.aws.cloud.qdrant.io:6333', key: 'test-secret', collection: 'restore_test' };
const signal = () => AbortSignal.timeout(5000);
const info = { result: { config: { params: { vectors: { size: 768, distance: 'Cosine' }, sparse_vectors: { [LEXICAL_VECTOR]: { modifier: 'idf' } } } } } };

test('Qdrant config only accepts Cloud HTTPS endpoints, never browser paths or credential URLs', () => {
  for (const url of ['', 'http://cluster.cloud.qdrant.io', 'https://localhost:6333', 'https://example.com', 'https://x.cloud.qdrant.io/dashboard', 'https://key@x.cloud.qdrant.io', 'https://x.cloud.qdrant.io?key=secret']) {
    assert.throws(() => qdrantConfig({ QDRANT_URL: url, QDRANT_API_KEY: 'secret', QDRANT_COLLECTION: 'restore' }));
  }
  assert.equal(qdrantConfig({ QDRANT_URL: 'https://x.cloud.qdrant.io', QDRANT_API_KEY: 'secret', QDRANT_COLLECTION: 'restore' }).endpoint, 'https://x.cloud.qdrant.io:6333');
});

test('Qdrant creates 768/Cosine collection and indexed payload filters; refuses incompatible collections', async () => {
  const requests: Array<{ method?: string; url: string; body: any }> = [];
  let exists = false;
  const store = new QdrantStore(config, async (url, options) => {
    assert.equal((options?.headers as Record<string, string>)['api-key'], 'test-secret');
    assert.equal(options?.redirect, 'error');
    assert.ok(!String(url).includes('test-secret'));
    const body = options?.body ? JSON.parse(String(options.body)) : undefined;
    requests.push({ method: options?.method, url: String(url), body });
    if (options?.method === 'GET') return exists ? Response.json(info) : new Response('', { status: 404 });
    exists = true; return Response.json({ result: true });
  });
  await store.ensureCollection(signal());
  assert.deepEqual(requests.find((r) => r.method === 'PUT' && !r.url.includes('/index'))!.body, info.result.config.params);
  assert.deepEqual(requests.filter((r) => r.url.includes('/index')).map((r) => r.body.field_name), ['model', 'documentId', 'generation']);
  const bad = new QdrantStore(config, async () => Response.json({ result: { config: { params: { vectors: { size: 1536, distance: 'Cosine' } } } } }));
  await assert.rejects(bad.ensureCollection(signal()), { code: 'QDRANT_COLLECTION_MISMATCH' });
});

test('Qdrant upserts with acknowledgement and searches only the selected embedding model', async () => {
  const id = randomUUID();
  const store = new QdrantStore(config, async (url, options) => {
    const body = JSON.parse(String(options?.body));
    if (String(url).includes('/query')) {
      assert.deepEqual(body.filter, { must: [{ key: 'model', match: { value: 'gemini-embedding-2' } }] });
      assert.equal(body.with_vector, false); assert.equal(body.with_payload, false); assert.equal(body.offset, 40);
      assert.deepEqual(body.query, { fusion: 'rrf' });
      assert.equal(body.score_threshold, undefined);
      assert.equal(body.prefetch.length, 2);
      for (const branch of body.prefetch) {
        assert.deepEqual(branch.filter, body.filter);
        assert.ok(branch.limit >= body.offset + body.limit);
      }
      assert.equal(body.prefetch[0].score_threshold, 0.55);
      assert.equal(body.prefetch[1].using, LEXICAL_VECTOR);
      assert.deepEqual(body.prefetch[1].query, lexicalVector('tin nháp'));
      return Response.json({ result: { points: [{ id, score: 0.25, payload: { text: 'untrusted' } }] } });
    }
    assert.ok(String(url).includes('wait=true')); assert.ok(String(url).includes('ordering=strong'));
    if (options?.method === 'PUT') {
      assert.equal(body.points[0].vector[''].length, 768);
      assert.deepEqual(body.points[0].vector[LEXICAL_VECTOR], lexicalVector('tin nháp'));
      assert.equal(body.points[0].lexical, undefined);
    }
    return Response.json({ result: { status: 'completed' } });
  });
  const vector = Array(768).fill(0.1);
  await store.upsert([{ id, vector, lexical: lexicalVector('tin nháp'), payload: { documentId: 'policy', generation: 'g', model: 'gemini-embedding-2', version: 'v', ordinal: 0 } }], signal());
  assert.deepEqual(await store.search(vector, 'gemini-embedding-2', 40, signal(), 'tin nháp'), [{ id, score: 0.25 }]);
  await store.remove([id], signal());
  const pending = new QdrantStore(config, async () => Response.json({ result: { status: 'acknowledged' } }));
  await assert.rejects(pending.remove([id], signal()), { code: 'QDRANT_WRITE_PENDING' });
});

test('Qdrant rejects malformed hits and redacts access/transport errors', async () => {
  const invalid = new QdrantStore(config, async () => Response.json({ result: { points: [{ id: 'not-a-uuid', score: 'bad' }] } }));
  await assert.rejects(invalid.search([1], 'model', 0, signal(), 'test'), { code: 'QDRANT_RESPONSE_INVALID' });
  const denied = new QdrantStore(config, async () => new Response('test-secret upstream details', { status: 403 }));
  await assert.rejects(denied.ensureCollection(signal()), (error: any) => error.code === 'QDRANT_ACCESS_DENIED' && !error.message.includes('test-secret'));
  const missing = new QdrantStore(config, async () => new Response('', { status: 404 }));
  await missing.remove([randomUUID()], signal());
});

test('existing dense collection gains a sparse index without replacing or deleting data', async () => {
  let upgraded = false;
  const store = new QdrantStore(config, async (url, options) => {
    assert.notEqual(options?.method, 'DELETE');
    if (options?.method === 'GET') return Response.json(upgraded ? info : { result: { config: { params: { vectors: info.result.config.params.vectors } } } });
    if (String(url).endsWith(`/vectors/${LEXICAL_VECTOR}`)) {
      assert.equal(options?.method, 'PUT');
      assert.deepEqual(JSON.parse(String(options?.body)), { sparse: { modifier: 'idf' } });
      upgraded = true;
    } else assert.ok(String(url).includes('/index'));
    return Response.json({ result: true });
  });
  await store.ensureCollection(signal());
  assert.equal(upgraded, true);
});

test('stopword-only query skips the empty sparse branch and still uses rank fusion', async () => {
  const store = new QdrantStore(config, async (_url, options) => {
    const body = JSON.parse(String(options?.body));
    assert.equal(body.prefetch.length, 1);
    assert.deepEqual(body.query, { fusion: 'rrf' });
    return Response.json({ result: { points: [] } });
  });
  assert.deepEqual(await store.search([1], 'model', 0, signal(), 'và là của'), []);
});

test('concurrent collection upgrade accepts the sparse vector already created by another indexer', async () => {
  let reads = 0;
  const store = new QdrantStore(config, async (url, options) => {
    if (options?.method === 'GET') {
      return Response.json(++reads === 1 ? { result: { config: { params: { vectors: info.result.config.params.vectors } } } } : info);
    }
    if (String(url).includes('/vectors/')) return new Response('', { status: 409 });
    return Response.json({ result: true });
  });
  await store.ensureCollection(signal());
  assert.ok(reads >= 2);
});
