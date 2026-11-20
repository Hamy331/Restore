export const EMBEDDING_DIMENSIONS = 768;
export type SparseVector = { indices: number[]; values: number[] };
export type VectorPoint = { id: string; vector: number[]; lexical: SparseVector; payload: { documentId: string; generation: string; model: string; version: string; ordinal: number; price?: number; categoryId?: string } };
export type VectorFilters = { minPrice?: number; maxPrice?: number; categoryId?: string };
export type VectorHit = { id: string; score: number };
export interface VectorStore {
  readonly collection: string;
  ensureCollection(signal: AbortSignal): Promise<void>;
  upsert(points: VectorPoint[], signal: AbortSignal): Promise<void>;
  search(vector: number[], model: string, offset: number, signal: AbortSignal, query: string, filters?: VectorFilters): Promise<VectorHit[]>;
  remove(ids: string[], signal: AbortSignal): Promise<void>;
}
