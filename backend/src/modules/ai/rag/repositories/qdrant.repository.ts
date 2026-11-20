import { z } from 'zod';
import { AppError } from '../../../../common/errors/app-error.js';
import { EMBEDDING_DIMENSIONS, type VectorFilters, type VectorHit, type VectorPoint, type VectorStore } from '../rag.type.js';
import { lexicalVector, LEXICAL_VECTOR } from '../services/lexical.service.js';
import { SEARCH_LIMITS } from '../../ai.config.js';

export function qdrantConfig(env: NodeJS.ProcessEnv = process.env) {
  let endpoint: URL;
  try { endpoint = new URL(env.QDRANT_URL ?? ''); } catch {
    throw new AppError(503, 'QDRANT_NOT_CONFIGURED', 'Chưa cấu hình Qdrant Cloud.');
  }
  if (endpoint.protocol !== 'https:' || !endpoint.hostname.endsWith('.cloud.qdrant.io') ||
      endpoint.username || endpoint.password || endpoint.search || endpoint.hash || !['', '/'].includes(endpoint.pathname)) {
    throw new AppError(503, 'QDRANT_CONFIG_INVALID', 'QDRANT_URL phải là HTTPS Cluster Endpoint của Qdrant Cloud.');
  }
  const key = env.QDRANT_API_KEY?.trim(), collection = env.QDRANT_COLLECTION?.trim();
  if (!key || !collection || !/^[a-zA-Z0-9_-]{1,100}$/.test(collection)) {
    throw new AppError(503, 'QDRANT_NOT_CONFIGURED', 'Cần QDRANT_API_KEY và tên QDRANT_COLLECTION hợp lệ.');
  }
  // Qdrant Cloud REST defaults to 6333 when users copy a hostname without a port.
  if (!endpoint.port) endpoint.port = '6333';
  return { endpoint: endpoint.origin, key, collection };
}

/** REST adapter: no SDK dependency, no localhost fallback, no credential-bearing URLs. */
export class QdrantStore implements VectorStore {
  readonly collection: string;
  private readonly base: string;
  constructor(private readonly config: ReturnType<typeof qdrantConfig>, private readonly fetcher: typeof fetch = fetch) {
    this.collection = config.collection;
    this.base = `${config.endpoint}/collections/${encodeURIComponent(config.collection)}`;
  }

  protected async request(method: string, path: string, body: unknown, signal: AbortSignal, allowMissing = false) {
    try {
      const response = await this.fetcher(this.base + path, {
        method, headers: { 'Content-Type': 'application/json', 'api-key': this.config.key },
        ...(body === undefined ? {} : { body: JSON.stringify(body) }),
        redirect: 'error', signal,
      });
      if (response.status === 404 && allowMissing) return null;
      if (response.status === 401 || response.status === 403) throw new AppError(503, 'QDRANT_ACCESS_DENIED', 'Qdrant từ chối quyền truy cập. Kiểm tra Cluster API key.');
      if (!response.ok) throw new Error('Qdrant request failed');
      return await response.json();
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw new AppError(503, 'QDRANT_UNAVAILABLE', 'Chưa kết nối được kho tài liệu AI. Vui lòng thử lại.');
    }
  }

  async ensureCollection(signal: AbortSignal) {
    let info = await this.request('GET', '', undefined, signal, true);
    if (!info) {
      // Concurrent initializers may both see 404. Re-read after either create wins.
      try { await this.request('PUT', '', { vectors: { size: EMBEDDING_DIMENSIONS, distance: 'Cosine' }, sparse_vectors: { [LEXICAL_VECTOR]: { modifier: 'idf' } } }, signal); }
      catch (error) {
        info = await this.request('GET', '', undefined, signal, true);
        if (!info) throw error;
      }
      info ??= await this.request('GET', '', undefined, signal);
    }
    const parsed = z.object({ result: z.object({ config: z.object({ params: z.object({ vectors: z.object({ size: z.literal(768), distance: z.literal('Cosine') }) }) }) }) }).safeParse(info);
    if (!parsed.success) throw new AppError(503, 'QDRANT_COLLECTION_MISMATCH', 'Collection phải dùng vector 768 chiều và Cosine. Hãy chọn collection riêng cho Restore.');
    if (info.result.config.params.sparse_vectors?.[LEXICAL_VECTOR]?.modifier !== 'idf') {
      // Additive upgrade: retains the existing dense vector and every point.
      try { await this.request('PUT', `/vectors/${LEXICAL_VECTOR}`, { sparse: { modifier: 'idf' } }, signal); }
      catch (error) {
        // Another document indexer may have added the vector after our initial GET.
        const concurrent = await this.request('GET', '', undefined, signal);
        if (concurrent?.result?.config?.params?.sparse_vectors?.[LEXICAL_VECTOR]?.modifier !== 'idf') throw error;
      }
      const updated = await this.request('GET', '', undefined, signal);
      if (updated?.result?.config?.params?.sparse_vectors?.[LEXICAL_VECTOR]?.modifier !== 'idf') {
        throw new AppError(503, 'QDRANT_COLLECTION_MISMATCH', 'Collection chưa có chỉ mục từ khóa lexical_v1/IDF.');
      }
    }
    for (const field of ['model', 'documentId', 'generation']) {
      await this.request('PUT', '/index?wait=true', { field_name: field, field_schema: 'keyword' }, signal);
    }
  }

  async upsert(points: VectorPoint[], signal: AbortSignal) {
    if (!points.length) return;
    if (points.some((point) => point.vector.length !== EMBEDDING_DIMENSIONS || point.vector.some((v) => !Number.isFinite(v)))) {
      throw new AppError(503, 'AI_EMBEDDING_INVALID', 'Vector tài liệu không hợp lệ.');
    }
    const result = await this.request('PUT', '/points?wait=true&ordering=strong', {
      points: points.map(({ vector, lexical, ...point }) => ({ ...point, vector: { '': vector, [LEXICAL_VECTOR]: lexical } })),
    }, signal);
    if (result?.result?.status !== 'completed') throw new AppError(503, 'QDRANT_WRITE_PENDING', 'Qdrant chưa xác nhận lưu chỉ mục. Hãy thử lại.');
  }

  async search(vector: number[], model: string, offset: number, signal: AbortSignal, query: string, filters: VectorFilters = {}): Promise<VectorHit[]> {
    const must: unknown[] = [{ key: 'model', match: { value: model } }];
    if (filters.minPrice !== undefined || filters.maxPrice !== undefined) must.push({ key: 'price', range: { gte: filters.minPrice, lte: filters.maxPrice } });
    if (filters.categoryId) must.push({ key: 'categoryId', match: { value: filters.categoryId } });
    const filter = { must };
    const lexical = lexicalVector(query);
    // Both branches search independently. A lexical-only hit can enter the final result.
    // Fixed prefetch bounds keep pagination/ranks stable across the five SQL-validation pages.
    const prefetch = [
      { query: vector, filter, limit: SEARCH_LIMITS.candidates, score_threshold: 0.55 },
      ...(lexical.indices.length ? [{ query: lexical, using: LEXICAL_VECTOR, filter, limit: SEARCH_LIMITS.candidates, score_threshold: 0.000001 }] : []),
    ];
    const result = await this.request('POST', '/points/query', {
      prefetch, query: { fusion: 'rrf' }, filter,
      limit: SEARCH_LIMITS.pageSize, offset, with_payload: false, with_vector: false,
    }, signal);
    const parsed = z.object({ result: z.object({ points: z.array(z.object({ id: z.string().uuid(), score: z.number().finite() })) }) }).safeParse(result);
    if (!parsed.success) throw new AppError(503, 'QDRANT_RESPONSE_INVALID', 'Kho tài liệu trả về dữ liệu không hợp lệ.');
    return parsed.data.result.points;
  }

  async remove(ids: string[], signal: AbortSignal) {
    if (!ids.length) return;
    const result = await this.request('POST', '/points/delete?wait=true&ordering=strong', { points: ids }, signal, true);
    // An absent collection already contains none of these points.
    if (result !== null && result?.result?.status !== 'completed') throw new AppError(503, 'QDRANT_WRITE_PENDING', 'Qdrant chưa xác nhận xóa chỉ mục.');
  }
}

export const configuredVectorStore = (): VectorStore => new QdrantStore(qdrantConfig());
