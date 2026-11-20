/** Overlap keeps short sentences near chunk boundaries in the retrieved context. */
export function chunkText(text: string): string[] {
  const chunks: string[] = [];
  for (let offset = 0; offset < text.length; offset += 1300) {
    const chunk = text.slice(offset, offset + 1500).trim();
    if (chunk) chunks.push(chunk);
  }
  return chunks;
}
