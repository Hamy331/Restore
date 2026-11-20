import { z } from 'zod';

export const conversationId = z.string().uuid();
export const messageBody = z.object({
  requestId: z.string().uuid(),
  message: z.string().trim().min(1).max(2000),
}).strict();
export const searchArgs = z.object({
  q: z.string().max(100),
  minPrice: z.string().regex(/^\d{1,12}$/).optional(),
  maxPrice: z.string().regex(/^\d{1,12}$/).optional(),
  categoryId: z.string().max(100).optional(),
  brand: z.string().trim().min(1).max(80).optional(),
}).strict().refine((value) => !value.minPrice || !value.maxPrice || Number(value.minPrice) <= Number(value.maxPrice), { message: 'Giá thấp nhất phải không lớn hơn giá cao nhất.' });
export const detailsArgs = z.object({ ids: z.array(z.string().min(1).max(100)).min(1).max(3) }).strict();
export const knowledgeArgs = z.object({ query: z.string().trim().min(2).max(300) }).strict();
export const noArgs = z.object({}).strict();
export const draftArgs = z.object({
  title: z.string().trim().min(5).max(70),
  description: z.string().trim().min(10).max(1500),
  price: z.string().regex(/^(0|[1-9]\d{0,11})$/),
}).strict();
