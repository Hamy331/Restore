import { z } from 'zod';

const value = z.string().trim().min(1).max(100).nullable();
const price = z.string().regex(/^\d{1,12}$/).nullable();
export const slotsSchema = z.object({
  query: value.optional(), categoryId: value.optional(), brand: value.optional(),
  minPrice: price.optional(), maxPrice: price.optional(), preferences: value.optional(),
  area: value.optional(), condition: value.optional(),
  attributes: z.record(z.string().min(1).max(60), value).refine(v => Object.keys(v).length <= 12).optional(),
}).strict();
export const extractionSchema = z.object({
  intent: z.enum(['shopping', 'knowledge', 'quota', 'unclear', 'offscope']),
  slots: slotsSchema,
  newSearch: z.boolean(), searchNow: z.boolean(),
}).strict();
export type Extraction = z.infer<typeof extractionSchema>;
const stateSchema = z.object({
  version: z.literal(1), intent: z.enum(['shopping', 'knowledge', 'quota']).nullable(),
  slots: slotsSchema, pending: z.enum(['query', 'budget']).nullable(),
  results: z.array(z.string().min(1).max(100)).max(5),
  selected: z.array(z.string().min(1).max(100)).max(3),
  unclearCount: z.number().int().min(0).max(3),
}).strict();
export type ConversationState = z.infer<typeof stateSchema>;
export function emptyState(): ConversationState {
  return { version: 1, intent: null, slots: {}, pending: null, results: [], selected: [], unclearCount: 0 };
}
export function readState(input: unknown): ConversationState {
  const parsed = stateSchema.safeParse(input);
  return parsed.success ? parsed.data : emptyState();
}
/** Pure reducer: undefined preserves a slot; null explicitly removes its constraint. */
export function applyExtraction(previous: ConversationState, change: Extraction): ConversationState {
  const state = structuredClone(previous);
  if (change.intent === 'unclear' || change.intent === 'offscope') return state;
  state.intent = change.intent;
  state.unclearCount = 0;
  if (change.intent !== 'shopping') { state.pending = null; return state; }
  if (change.newSearch || (change.slots.categoryId && previous.slots.categoryId && change.slots.categoryId !== previous.slots.categoryId)) {
    state.slots = {}; state.results = []; state.selected = [];
  }
  state.slots = { ...state.slots, ...change.slots, ...(change.slots.attributes ? { attributes: { ...state.slots.attributes, ...change.slots.attributes } } : {}) };
  state.pending = null;
  return state;
}
