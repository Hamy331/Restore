import { AppError } from '../../../../common/errors/app-error.js';
import { QdrantStore, qdrantConfig } from '../../rag/repositories/qdrant.repository.js';

class ListingVectorStore extends QdrantStore {
  override async ensureCollection(signal: AbortSignal) {
    await super.ensureCollection(signal);
    await this.request('PUT', '/index?wait=true', { field_name: 'price', field_schema: 'float' }, signal);
    await this.request('PUT', '/index?wait=true', { field_name: 'categoryId', field_schema: 'keyword' }, signal);
  }
}

export function listingVectorStore() {
  const config = qdrantConfig();
  const collection = process.env.QDRANT_LISTING_COLLECTION?.trim() || `${config.collection}_listings`;
  if (collection === config.collection || !/^[a-zA-Z0-9_-]{1,100}$/.test(collection)) {
    throw new AppError(503, 'QDRANT_CONFIG_INVALID', 'Collection sản phẩm phải khác collection tài liệu.');
  }
  return new ListingVectorStore({ ...config, collection });
}
