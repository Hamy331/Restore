import { AppError } from '../../../../common/errors/app-error.js';

/** Parse SSE across arbitrary UTF-8/network boundaries; bound upstream memory use. */
export async function* sseData(body: ReadableStream<Uint8Array>) {
  const reader = body.getReader(), decoder = new TextDecoder();
  let buffer = '', data: string[] = [], size = 0;
  try {
    while (true) {
      const { value, done } = await reader.read();
      buffer += decoder.decode(value, { stream: !done });
      size += value?.length ?? 0;
      if (size > 256000 || buffer.length > 64000) throw new AppError(503, 'AI_OUTPUT_LIMIT', 'Câu trả lời AI vượt giới hạn.');
      let end: number;
      while ((end = buffer.indexOf('\n')) >= 0) {
        const line = buffer.slice(0, end).replace(/\r$/, ''); buffer = buffer.slice(end + 1);
        if (!line) { if (data.length) { yield data.join('\n'); data = []; } }
        else if (line.startsWith('data:')) data.push(line.slice(5).trimStart());
      }
      if (done) {
        if (buffer.startsWith('data:')) data.push(buffer.slice(5).trim());
        if (data.length) yield data.join('\n');
        return;
      }
    }
  } finally { await reader.cancel().catch(() => {}); reader.releaseLock(); }
}
