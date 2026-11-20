import type { AssistantEvent } from '../assistant.type.js';
import type { ToolSession } from './tools.service.js';
import { decide, type Decision } from './dialogue.service.js';
import { evidenceFallback } from './output-guard.service.js';

export async function executeShopping(decision: Decision, session: ToolSession, emit: ((event: AssistantEvent) => void) | undefined, signal: AbortSignal) {
  if (decision.cheaper) {
    emit?.({ type: 'status', stage: 'reading_listings' });
    const data = await session.execute('listing_details', { ids: [decision.cheaper] }) as { items: { price: string }[] };
    signal.throwIfAborted();
    session.reply.listings = [];
    if (!data.items.length) {
      decision.state.selected = [];
      session.reply.text = 'Tin được chọn không còn khả dụng. Bạn chọn tin khác hoặc tìm lại nhé.'; return;
    }
    const maxPrice = Math.min(Math.ceil(Number(data.items[0].price)) - 1, Number(decision.state.slots.maxPrice ?? Infinity));
    if (maxPrice < 0 || (decision.state.slots.minPrice && Number(decision.state.slots.minPrice) > maxPrice)) {
      session.reply.text = 'Không thể tìm rẻ hơn với mức giá tối thiểu hiện tại. Bạn muốn đổi khoảng giá không?'; return;
    }
    decision.state.slots.maxPrice = String(maxPrice);
    const search = decide(decision.state, { intent: 'shopping', slots: {}, newSearch: false, searchNow: true });
    decision.search = search.search;
    if (!decision.search) { session.reply.text = 'Bạn muốn tìm rẻ hơn loại sản phẩm nào?'; return; }
  }
  const tool = decision.details ? 'listing_details' : 'search_listings';
  emit?.({ type: 'status', stage: decision.details ? 'reading_listings' : 'searching_listings' });
  const data = await session.execute(tool, decision.details ? { ids: decision.details } : decision.search) as { items: Record<string, unknown>[] };
  signal.throwIfAborted();
  if (!decision.details) {
    decision.state.results = session.reply.listings.map(item => item.id);
    decision.state.selected = [];
  } else {
    const visible = new Set(session.reply.listings.map(item => item.id));
    decision.state.selected = decision.state.selected.filter(id => visible.has(id));
  }
  session.reply.text = data.items.length ? evidenceFallback([{ tool, data }]) : 'Mình chưa tìm thấy dữ liệu phù hợp trong kết quả hiện tại. Bạn muốn đổi hoặc bỏ điều kiện nào?';
  if (decision.details) {
    for (const item of data.items) {
      const details = [item.description, item.condition ? `Tình trạng: ${item.condition}` : '', ...Object.entries((item.attributes ?? {}) as Record<string, unknown>).map(([key, value]) => `${key}: ${String(value)}`)].filter(Boolean).join('\n');
      if (details) session.reply.text += `\n\n${item.title}:\n${details.slice(0, 1500)}`;
    }
    if (data.items.length < decision.details.length) session.reply.text += '\nMột số tin đã không còn khả dụng.';
  }
  if (!decision.details && (decision.state.slots.preferences || decision.state.slots.area || decision.state.slots.condition || Object.values(decision.state.slots.attributes ?? {}).some(Boolean))) {
    session.reply.text += '\nCác nhu cầu về thuộc tính và khu vực được dùng để tìm theo nội dung; hãy xem chi tiết tin để kiểm tra mức độ phù hợp.';
  }
  session.reply.text = session.reply.text.slice(0, 8000);
}


