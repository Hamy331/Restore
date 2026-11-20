import { redact, redactValue } from '../../../../common/security/redaction.js';
import type { AiProvider, Content } from '../assistant.type.js';
import { NO_EVIDENCE, requiredTools } from './input-guard.service.js';

export type Evidence = { tool: string; data: unknown };
const record = (v: unknown): Record<string, any> => v && typeof v === 'object' ? v as Record<string, any> : {};
const listingTools = new Set(['search_listings', 'listing_details']);
const moneyPattern = () => /(\d[\d.,\s]*?)\s*(triệu|trieu|tr\b|nghìn|nghin|ngàn|ngan|k\b|tỷ|ty\b|đồng|dong|đ(?=\s|[.,!?;)]|$)|₫|VND)/gi;
function moneyAmount(raw: string, unit: string): string {
  unit = unit.toLowerCase();
  const multiplier = /^(triệu|trieu|tr)$/.test(unit) ? 1e6 : /^(nghìn|nghin|ngàn|ngan|k)$/.test(unit) ? 1e3 : /^(tỷ|ty)$/.test(unit) ? 1e9 : 1;
  raw = raw.replace(/\s/g, '');
  return String(multiplier === 1 ? Number(raw.replace(/[.,]/g, '')) : Number(raw.replace(',', '.')) * multiplier);
}

function hasData(e: Evidence): boolean {
  const data = record(e.data);
  if (listingTools.has(e.tool)) return Array.isArray(data.items) && data.items.length > 0;
  if (e.tool === 'search_knowledge') return Array.isArray(data.sources) && data.sources.length > 0;
  return e.tool === 'my_quota' && Object.keys(data).length > 0;
}

export function missingEvidence(message: string, history: Content[], evidence: Evidence[]): boolean {
  return requiredTools(message, history).some(tool => !evidence.some(e => (tool === 'listings' ? listingTools.has(e.tool) : e.tool === tool) && hasData(e)));
}

/** Known facts only; used when generated prose cannot be verified. */
export function evidenceFallback(evidence: Evidence[]): string {
  const lines: string[] = [];
  const seen = new Set<string>();
  for (const e of evidence) {
    const data = record(e.data);
    if (listingTools.has(e.tool)) for (const item of data.items ?? []) {
      if (seen.has(item.id)) continue;
      seen.add(item.id);
      lines.push(`${item.title} — ${Number(item.price).toLocaleString('vi-VN')} đ${item.areaLabel ? ` — ${item.areaLabel}` : ''} (mã tin: ${item.id}).`);
    }
    if (e.tool === 'search_knowledge') for (const source of data.sources ?? []) {
      lines.push(`Theo tài liệu “${source.title}” [nguồn:${source.id}]:\n${String(source.text).slice(0, 1200)}`);
    }
    if (e.tool === 'my_quota') {
      if (data.plan?.name) lines.push(`Gói hiện tại: ${data.plan.name}.`);
      for (const [label, values] of [['Đã sử dụng', data.usage], ['Còn lại', data.remaining]] as const) {
        for (const [key, value] of Object.entries(record(values))) {
          const name = ({ drafts: 'tin nháp', today: 'tin đăng hôm nay', active: 'tin đang hiển thị', listings: 'tin đăng', boosts: 'lượt đẩy tin', listingsToday: 'tin có thể đăng hôm nay', activeListings: 'tin đang hiển thị', promotionsThisMonth: 'lượt đẩy tin trong tháng' } as Record<string, string>)[key] ?? key;
          if (typeof value === 'number' || value === null) lines.push(`${label} (${name}): ${value === null ? 'không giới hạn' : value}.`);
        }
      }
    }
  }
  return redact(lines.length ? `Dữ liệu mình vừa kiểm tra được:\n${lines.join('\n')}` : NO_EVIDENCE).slice(0, 8000);
}

/** Hard checks for amounts, identifiers and citations before semantic verification. */
export function referencesMatch(text: string, evidence: Evidence[]): boolean {
  const data = JSON.stringify(evidence);
  const prices = new Set(evidence.flatMap(e => listingTools.has(e.tool) ? (record(e.data).items ?? []).map((i: any) => String(Number(i.price))) : []));
  const numbers = new Set<string>();
  function collect(value: unknown) {
    if (typeof value === 'number') numbers.add(String(value));
    else if (typeof value === 'string') {
      if (/^\d+(\.\d+)?$/.test(value)) numbers.add(String(Number(value)));
      for (const m of value.matchAll(/(?<![\p{L}\p{N}_])\d+(?:[.,]\d+)*(?![\p{L}\p{N}_])/gu)) numbers.add(m[0].replace(/[.,]/g, ''));
      for (const m of value.matchAll(moneyPattern())) prices.add(moneyAmount(m[1], m[2]));
    } else if (value && typeof value === 'object') Object.values(value).forEach(collect);
  }
  evidence.forEach(e => collect(e.data));
  const uuids = text.match(/\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b/gi) ?? [];
  if (uuids.some(id => !data.includes(id))) return false;
  for (const m of text.matchAll(/(?:mã tin|ma tin|listing id)\s*[:#]\s*([\w-]+)/gi)) {
    if (!evidence.some(e => listingTools.has(e.tool) && (record(e.data).items ?? []).some((i: any) => i.id === m[1]))) return false;
  }
  const citations = [...text.matchAll(/\[(?:nguồn|source):([^\]]+)\]/gi)].map(m => m[1]);
  const sources = evidence.flatMap(e => e.tool === 'search_knowledge' ? record(e.data).sources ?? [] : []);
  if (citations.some(id => !sources.some((s: any) => s.id === id))) return false;
  const urls = text.match(/https?:\/\/[^\s)\]]+/g) ?? [];
  if (urls.some(url => !data.includes(url))) return false;
  for (const m of text.matchAll(moneyPattern())) {
    if (!prices.has(moneyAmount(m[1], m[2]))) return false;
  }
  const withoutReferences = text.replace(moneyPattern(), '').replace(/\[(?:nguồn|source):[^\]]+\]/gi, '').replace(/\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b/gi, '');
  for (const m of withoutReferences.matchAll(/(?<![\p{L}\p{N}_])\d+(?:[.,]\d+)*(?![\p{L}\p{N}_])/gu)) {
    if (!numbers.has(m[0].replace(/[.,]/g, ''))) return false;
  }
  return true;
}

export async function guardedAnswer(provider: AiProvider, message: string, history: Content[], candidate: string, evidence: Evidence[], signal: AbortSignal): Promise<string> {
  const safe = redact(candidate);
  if (missingEvidence(message, history, evidence)) return NO_EVIDENCE;
  // A response making factual claims also needs evidence, even for an ambiguous input.
  if (missingEvidence(safe, [], evidence)) return evidenceFallback(evidence);
  if (!referencesMatch(safe, evidence)) return evidenceFallback(evidence);
  if (!evidence.length) {
    // No free-form factual answer without a current tool result. Clarifications and
    // greetings are handled locally; ambiguous questions are redirected safely.
    return 'Bạn muốn tìm sản phẩm hay hỏi nội dung nào về ReStore? Bạn nói rõ thêm giúp mình nhé.';
  }
  if (!evidence.some(hasData)) return NO_EVIDENCE;
  const needsSources = requiredTools(message, history).includes('search_knowledge');
  if (needsSources && !/\[(?:nguồn|source):[^\]]+\]/i.test(safe)) return evidenceFallback(evidence);
  // A failed, malformed, timed out or unavailable verifier never approves prose.
  try {
    const verificationSignal = AbortSignal.any([signal, AbortSignal.timeout(10_000)]);
    if (provider.verifyGrounding && await provider.verifyGrounding({ question: redact(message), answer: safe, evidence: redactValue(evidence) }, verificationSignal)) return safe;
  } catch { /* Fall back to facts returned by current tools. */ }
  signal.throwIfAborted();
  return evidenceFallback(evidence);
}
