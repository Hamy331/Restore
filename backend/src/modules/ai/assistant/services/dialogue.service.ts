import type { AiProvider, AssistantReply } from '../assistant.type.js';
import { inputReply, CLARIFY, normalize, requiredTools } from './input-guard.service.js';
import { applyExtraction, emptyState, extractionSchema, type ConversationState, type Extraction } from './conversation-state.js';
import { searchArgs } from '../assistant.validator.js';

export type CategoryOption = { id: string; name: string; attributes?: { key: string; label?: { vi: string } }[] };
export type Decision = { state: ConversationState; reply?: AssistantReply; search?: ReturnType<typeof searchArgs.parse>; details?: string[]; cheaper?: string };
const reply = (state: ConversationState, text: string, suggestions?: string[]): Decision => ({ state, reply: { text, listings: [], sources: [], ...(suggestions ? { suggestions } : {}) } });
const choices = ['Tìm sản phẩm', 'Hỏi về ReStore', 'Bắt đầu lại'];

export function unclear(previous: ConversationState): Decision {
  const state = structuredClone(previous);
  state.unclearCount = Math.min(3, state.unclearCount + 1);
  const text = state.unclearCount >= 3 ? 'Mình chưa hiểu yêu cầu. Bạn chọn một hướng bên dưới nhé.'
    : state.unclearCount === 2 ? (state.pending === 'budget' ? 'Bạn có thể nhập “dưới 5 triệu” hoặc “không giới hạn ngân sách”.' : 'Ví dụ: “Tìm ghế gỗ dưới 1 triệu” hoặc “Cách đăng tin trên ReStore?”.')
    : state.pending === 'budget' ? 'Bạn muốn chi khoảng bao nhiêu? Bạn cũng có thể nói “tìm luôn”.' : CLARIFY;
  return reply(state, text, state.unclearCount >= 3 ? choices : undefined);
}

export function localDecision(previous: ConversationState, message: string): Decision | undefined {
  const q = normalize(message).trim().replace(/[.!?]+$/, '');
  if (q === 'bat dau lai') return reply(emptyState(), 'Bạn muốn tìm sản phẩm hay hỏi về ReStore?', choices.slice(0, 2));
  if (q === 'tim san pham') { const state = emptyState(); state.intent = 'shopping'; state.pending = 'query'; return reply(state, 'Bạn muốn tìm sản phẩm gì?'); }
  if (q === 'hoi ve restore') return reply({ ...previous, intent: 'knowledge', pending: null, unclearCount: 0 }, 'Bạn muốn hỏi nội dung nào về ReStore?');
  const local = inputReply(message, true);
  if (local === CLARIFY) return unclear(previous);
  if (local) return reply({ ...previous, unclearCount: 0 }, local);
  const matches = [...q.matchAll(/(?:cai|mon|san pham)(?: thu)? (dau(?: tien)?|mot|hai|ba|tu|nam|\d+)/g)];
  if (matches.length) {
    const ordinals: Record<string, number> = { dau: 1, 'dau tien': 1, mot: 1, hai: 2, ba: 3, tu: 4, nam: 5 };
    const ids = matches.map(m => previous.results[(ordinals[m[1]] ?? Number(m[1])) - 1]);
    if (ids.some(id => !id) || ids.length > 3) return reply(previous, 'Bạn chọn sản phẩm nào trong danh sách vừa hiển thị? Mình có thể so sánh tối đa 3 sản phẩm.');
    const state = { ...previous, intent: 'shopping' as const, pending: null, selected: [...new Set(ids)], unclearCount: 0 };
    return { state, details: state.selected };
  }
  if (/^(?:re hon|co (?:cai|mon) nao re hon|tim (?:cai|mon) re hon)/.test(q)) {
    if (previous.selected.length !== 1) return reply(previous, 'Bạn muốn tìm rẻ hơn sản phẩm nào trong danh sách vừa rồi?');
    return { state: { ...previous, intent: 'shopping', unclearCount: 0, pending: null }, cheaper: previous.selected[0] };
  }
  const relevant = requiredTools(message, []);
  if (relevant.includes('my_quota') || relevant.includes('search_knowledge')) return { state: { ...previous, intent: relevant.includes('my_quota') ? 'quota' : 'knowledge', pending: null, unclearCount: 0 } };
  if (q === 'tiep tuc tim' && (previous.slots.query || previous.slots.categoryId)) return decide(previous, { intent: 'shopping', slots: {}, newSearch: false, searchNow: true });
  const amount = q.match(/^(?:(?:duoi|toi da|tam|khoang|ngan sach|tang len|doi thanh)\s+)?(\d+(?:[.,]\d+)?)\s*(trieu|tr|nghin|ngan|k|dong|vnd)?$/);
  if ((previous.pending === 'budget' || previous.intent === 'shopping') && amount) {
    const factor = /^(trieu|tr)$/.test(amount[2] ?? '') ? 1e6 : /^(nghin|ngan|k)$/.test(amount[2] ?? '') ? 1e3 : 1;
    if (!amount[2] && Number(amount[1]) < 1000) return reply(previous, 'Bạn muốn nói số tiền này theo đồng, nghìn hay triệu đồng?');
    const maxPrice = String(Number(amount[1].replace(',', '.')) * factor);
    if (!/^\d{1,12}$/.test(maxPrice)) return reply(previous, 'Bạn nhập lại ngân sách bằng số tiền VND hợp lệ nhé.');
    return decide(previous, { intent: 'shopping', slots: { maxPrice }, newSearch: false, searchNow: true });
  }
  if (previous.intent === 'shopping' || previous.pending === 'budget') {
    if (/^(?:khong gioi han(?: ngan sach)?|khong co ngan sach cu the)$/.test(q)) return decide(previous, { intent: 'shopping', slots: { minPrice: null, maxPrice: null }, newSearch: false, searchNow: true });
    if (/^(?:hang nao cung duoc|bo (?:loc )?hang)$/.test(q)) return decide(previous, { intent: 'shopping', slots: { brand: null }, newSearch: false, searchNow: true });
    if (/^(?:tim luon|tim giup minh truoc|khong biet|tiep tuc tim)$/.test(q)) return decide(previous, { intent: 'shopping', slots: {}, newSearch: false, searchNow: true });
  }
  return undefined;
}

export function decide(previous: ConversationState, change: Extraction): Decision {
  if (change.intent === 'unclear') return unclear(previous);
  if (change.intent === 'offscope') return reply({ ...previous, unclearCount: 0 }, 'Mình hỗ trợ tìm sản phẩm và giải đáp về ReStore.');
  const state = applyExtraction(previous, change);
  if (change.intent !== 'shopping') return { state };
  if (!state.slots.query && !state.slots.categoryId && !state.slots.brand) { state.pending = 'query'; return reply(state, 'Bạn muốn tìm sản phẩm gì?'); }
  const min = state.slots.minPrice, max = state.slots.maxPrice;
  if (min && max && Number(min) > Number(max)) return reply(previous, 'Giá tối thiểu đang lớn hơn giá tối đa. Bạn muốn tìm trong khoảng nào?');
  if (!change.searchNow && state.slots.maxPrice === undefined && previous.pending !== 'budget') {
    state.pending = 'budget'; return reply(state, 'Bạn muốn tìm trong khoảng ngân sách nào? Bạn có thể nói “không giới hạn” hoặc “tìm luôn”.');
  }
  const { query, preferences, area, condition, attributes, ...filters } = state.slots;
  const terms = [query, preferences, area, condition, ...Object.values(attributes ?? {})].filter(Boolean);
  const args = searchArgs.parse({ q: terms.join(' ').slice(0, 100), ...Object.fromEntries(Object.entries(filters).filter(([, v]) => v !== null)) });
  return { state, search: args };
}

export async function extractDecision(previous: ConversationState, message: string, provider: AiProvider, categories: CategoryOption[], signal: AbortSignal): Promise<Decision> {
  if (!provider.extractNeeds) return { state: previous }; // Compatibility for existing provider adapters.
  const parsed = extractionSchema.safeParse(await provider.extractNeeds({ message, state: previous, categories }, signal));
  if (!parsed.success) return reply(previous, 'Mình chưa xác định được nhu cầu. Bạn thử nói rõ sản phẩm hoặc điều kiện muốn đổi nhé.');
  if (parsed.data.slots.categoryId && !categories.some(c => c.id === parsed.data.slots.categoryId)) return reply(previous, 'Mình chưa xác định được danh mục. Bạn muốn tìm sản phẩm gì?');
  const category = categories.find(c => c.id === (parsed.data.slots.categoryId ?? (parsed.data.newSearch ? undefined : previous.slots.categoryId)));
  if (parsed.data.slots.attributes && Object.keys(parsed.data.slots.attributes).some(key => !category?.attributes?.some(a => a.key === key))) return reply(previous, 'Mình chưa xác định được thuộc tính hoặc danh mục. Bạn nói rõ loại sản phẩm cần tìm nhé.');
  return decide(previous, parsed.data);
}
