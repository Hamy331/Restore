import type { VectorPoint, VectorStore } from '../../../src/modules/ai/rag/rag.type.js';

/** Test double only; production requires the Qdrant Cloud adapter. */
export class MemoryVectorStore implements VectorStore {
  collection = 'restore_test';
  points = new Map<string, VectorPoint>();
  failUpsert = false;
  failDelete = false;
  async ensureCollection() {}
  async upsert(points: VectorPoint[]) {
    for (const point of points) this.points.set(point.id, point);
    if (this.failUpsert) throw new Error('write acknowledgement lost');
  }
  async search(_vector: number[], model: string, offset: number) {
    return [...this.points.values()].filter((p) => p.payload.model === model).slice(offset, offset + 40).map((p) => ({ id: p.id, score: 0.99 }));
  }
  async remove(ids: string[]) {
    if (this.failDelete) throw new Error('delete failed');
    for (const id of ids) this.points.delete(id);
  }
}
