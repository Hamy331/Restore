import assert from 'node:assert/strict';
import { test } from 'node:test';
import { chunkText } from './chunking.service.js';
import { rankChunks } from './ranking.service.js';
import { buildContext } from './context.service.js';
import { lexicalVector } from './lexical.service.js';

test('chunks are bounded, overlap and preserve Vietnamese source text', () => {
  const text = 'Chính sách đăng tin. '.repeat(180);
  const chunks = chunkText(text);
  assert.ok(chunks.length > 1);
  assert.ok(chunks.every((chunk) => chunk.length <= 1500));
  assert.ok(chunks[0].includes('Chính sách'));
  assert.deepEqual(chunkText('  '), []);
});
test('fusion ranking keeps low-scoring lexical-only candidates and removes duplicate points', () => {
  const chunks = [
    { id: 'dense', text: 'Đăng tin mới', score: 0.2 },
    { id: 'keyword-only', text: 'DRAFT_LIMIT_REACHED', score: 0.5 },
  ];
  assert.deepEqual(rankChunks([...chunks, chunks[0]]), [chunks[1], chunks[0]]);
  assert.deepEqual(rankChunks([]), []);
});

test('sparse tokens normalize Vietnamese while retaining product numbers and error terms', () => {
  assert.deepEqual(lexicalVector('GIỚI HẠN ĐĂNG TIN'), lexicalVector('gioi han dang tin'));
  assert.deepEqual(lexicalVector('  và là của ???'), { indices: [], values: [] });
  assert.notDeepEqual(lexicalVector('S23 Ultra'), lexicalVector('S24 Ultra'));
  assert.ok(lexicalVector('DRAFT_LIMIT_REACHED').indices.length === 3);
  const repeated = lexicalVector('Samsung Samsung');
  assert.equal(repeated.indices.length, 1);
  assert.ok(repeated.values[0] > 1 && repeated.values[0] < 2);
});
test('context uses only stored document metadata, without generated URLs', () => {
  assert.deepEqual(buildContext([{ documentId: 'policy', document: { title: 'Quy định' }, text: 'Nguồn thật' }]), [{ id: 'policy', title: 'Quy định', text: 'Nguồn thật' }]);
});
