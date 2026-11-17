import { z } from 'zod';
import { AppError } from '../../../../common/errors/app-error.js';
import type { AiProvider, Content, Declaration } from '../assistant.type.js';
import { SYSTEM_PROMPT } from './prompt.js';
import { sseData } from './sse.service.js';
import { redact, redactValue } from '../../../../common/security/redaction.js';

const part = z.object({
  text: z.string().optional(), thought: z.boolean().optional(), thoughtSignature: z.string().optional(),
  functionCall: z.object({ id: z.string().optional(), name: z.string(), args: z.unknown() }).optional(),
}).passthrough();
const generated = z.object({ candidates: z.array(z.object({
  finishReason: z.string().optional(), content: z.object({ role: z.literal('model'), parts: z.array(part) }).optional(),
})).optional() });

export class GeminiProvider implements AiProvider {
  readonly embeddingModel: string;
  private readonly model: string;
  constructor(private readonly key: string, private readonly fetcher: typeof fetch = fetch) {
    this.model = process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite';
    this.embeddingModel = process.env.GEMINI_EMBEDDING_MODEL || 'gemini-embedding-2';
    if (![this.model, this.embeddingModel].every((value) => /^[a-zA-Z0-9._-]+$/.test(value))) {
      throw new AppError(503, 'AI_CONFIG', 'Cấu hình model AI không hợp lệ.');
    }
  }

  private async request(model: string, method: string, body: unknown, signal: AbortSignal, stream = false) {
    try {
      const response = await this.fetcher(`https://generativelanguage.googleapis.com/v1beta/models/${model}:${method}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'x-goog-api-key': this.key },
        body: JSON.stringify(body), signal,
      });
      if (response.status === 429) throw new AppError(503, 'AI_PROVIDER_RATE_LIMIT', 'Gemini đã chạm hạn mức. Vui lòng đợi một lúc rồi thử lại.');
      if (response.status === 401 || response.status === 403) throw new AppError(503, 'AI_PROVIDER_ACCESS_DENIED', 'Gemini từ chối quyền truy cập. Kiểm tra API key và quyền dùng model.');
      if (response.status === 400 || response.status === 404) throw new AppError(503, 'AI_PROVIDER_REQUEST_INVALID', 'Yêu cầu hoặc model Gemini chưa phù hợp. Quản trị viên cần kiểm tra cấu hình.');
      if (!response.ok) throw new Error('Provider rejected request');
      return stream ? response : await response.json();
    } catch (error) {
      if (error instanceof AppError) throw error;
      // Never surface provider bodies, request headers or the key to logs/clients.
      throw new AppError(503, 'AI_UNAVAILABLE', 'AI chưa thể trả lời lúc này. Vui lòng thử lại.');
    }
  }

  async generate(contents: Content[], declarations: Declaration[], signal: AbortSignal, onText?: (text: string) => void): Promise<Content> {
    const body = {
      systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] }, contents: contents.map(content => content.role === 'model' ? content : redactValue(content)),
      tools: declarations.length ? [{ functionDeclarations: declarations }] : undefined,
      generationConfig: { maxOutputTokens: 4096, temperature: 0.2 },
    };
    if (onText) {
      const response: Response = await this.request(this.model, 'streamGenerateContent?alt=sse', body, signal, true);
      if (!response.body) throw new AppError(503, 'AI_NO_ANSWER', 'AI chưa tạo được câu trả lời.');
      const answer: Content = { role: 'model', parts: [] };
      let finish: string | undefined, length = 0;
      for await (const event of sseData(response.body)) {
        signal.throwIfAborted();
        const parsed = generated.safeParse(JSON.parse(event));
        if (!parsed.success) throw new AppError(503, 'AI_NO_ANSWER', 'Dữ liệu AI chưa đầy đủ.');
        const candidate = parsed.data.candidates?.[0];
        if (candidate?.finishReason) finish = candidate.finishReason;
        for (const item of candidate?.content?.parts ?? []) {
          answer.parts.push(item);
          if (item.text && !item.thought) {
            length += item.text.length;
            if (length > 8000) throw new AppError(503, 'AI_OUTPUT_LIMIT', 'Câu trả lời AI vượt giới hạn.');
            onText(item.text);
          }
        }
      }
      if (finish !== 'STOP' || !answer.parts.length) throw new AppError(503, 'AI_NO_ANSWER', 'Câu trả lời bị ngắt. Bạn thử lại nhé.');
      return answer;
    }
    const data = generated.safeParse(await this.request(this.model, 'generateContent', body, signal));
    const candidate = data.success ? data.data.candidates?.[0] : undefined;
    if (!candidate?.content || (candidate.finishReason && candidate.finishReason !== 'STOP')) {
      throw new AppError(503, 'AI_NO_ANSWER', 'AI chưa tạo được câu trả lời đầy đủ. Bạn thử hỏi lại nhé.');
    }
    // Return the original parts, including Gemini thought signatures for tool round trips.
    return candidate.content;
  }

  async embed(text: string, signal: AbortSignal): Promise<number[]> {
    const data = await this.request(this.embeddingModel, 'embedContent', {
      content: { parts: [{ text: redact(text) }] }, outputDimensionality: 768,
    }, signal);
    const parsed = z.object({ embedding: z.object({ values: z.array(z.number().finite()).length(768) }) }).safeParse(data);
    if (!parsed.success || !parsed.data.embedding.values.some((value) => value !== 0)) {
      throw new AppError(503, 'AI_EMBEDDING_INVALID', 'Chưa tạo được chỉ mục tài liệu.');
    }
    return parsed.data.embedding.values;
  }

}

export function configuredProvider(): AiProvider {
  if (process.env.AI_ENABLED !== 'true' || !process.env.GEMINI_API_KEY?.trim()) {
    throw new AppError(503, 'AI_NOT_CONFIGURED', 'Trợ lý AI chưa được bật. Vui lòng thử lại sau.');
  }
  return new GeminiProvider(process.env.GEMINI_API_KEY.trim());
}
