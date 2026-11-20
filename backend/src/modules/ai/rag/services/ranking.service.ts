/** RRF scores are ranks, not cosine similarities. Never apply a cosine cutoff here. */
export function rankChunks<T extends { id: string; score: number }>(chunks: T[]): T[] {
  const unique = new Map(chunks.map((chunk) => [chunk.id, chunk]));
  return [...unique.values()].sort((a, b) => b.score - a.score || a.id.localeCompare(b.id)).slice(0, 5);
}
