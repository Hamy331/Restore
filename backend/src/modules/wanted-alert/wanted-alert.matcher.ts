/**
 * Chấm điểm "gần giống" giữa mô tả món cần tìm (WantedAlert.keywords) và một
 * tin đăng (0..1). Cùng công thức với app (frontend
 * lib/modules/wanted_alert/utils/wanted_alert_matcher.dart).
 *
 * 1. Chuẩn hoá: chữ thường, bỏ dấu, bỏ ký tự đặc biệt, bỏ từ thừa
 *    ("cần", "mua", "tìm"...). Không bỏ "ban" vì vừa là "bán" vừa là "bàn".
 * 2. Mỗi từ khoá lấy từ giống nhất trong tiêu đề theo trigram (giống
 *    similarity() của pg_trgm), nên gõ sai nhẹ vẫn khớp. Độ phủ = trung bình
 *    điểm các từ khoá. Mô tả tin chỉ tính 80%.
 * 3. Điểm = 75% độ phủ + 25% trigram cả cụm so với tiêu đề.
 */

export type WantedAlertMatchLevel = 'BROAD' | 'BALANCED' | 'STRICT';

export const MATCH_THRESHOLDS: Record<WantedAlertMatchLevel, number> = {
  BROAD: 0.3,
  BALANCED: 0.45,
  STRICT: 0.6,
};

export const STOP_WORDS = new Set([
  'can', 'mua', 'tim', 'cho', 'va', 'voi', 'cua', 'loai', 'mot',
  'the', 'and', 'for', 'with', 'want', 'need', 'buy',
]);

/** Điểm từ khoá dưới mức này coi như không khớp */
export const TOKEN_FLOOR = 0.3;

/** Mô tả tin thường dài và lan man nên chỉ tính 80% */
export const DESCRIPTION_WEIGHT = 0.8;

/** Chữ thường, bỏ dấu tiếng Việt (kể cả đ), gộp khoảng trắng */
export const normalize = (input: string): string =>
  input
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/\s+/g, ' ')
    .trim();

/** Từ đã chuẩn hoá, bỏ từ thừa */
export const tokens = (text: string): string[] =>
  normalize(text)
    .replace(/[^a-z0-9]+/g, ' ')
    .split(' ')
    .filter((word) => word.length > 0 && !STOP_WORDS.has(word));

/** Trigram của từng từ, thêm 2 khoảng trắng đầu và 1 ở cuối (như pg_trgm) */
export const trigrams = (text: string): Set<string> => {
  const result = new Set<string>();
  for (const word of text.split(' ')) {
    if (!word) continue;
    const padded = `  ${word} `;
    for (let i = 0; i + 3 <= padded.length; i++) {
      result.add(padded.substring(i, i + 3));
    }
  }
  return result;
};

/** Số trigram chung / tổng trigram, như similarity() của pg_trgm */
export const similarity = (a: string, b: string): number => {
  const ta = trigrams(a);
  const tb = trigrams(b);
  if (ta.size === 0 || tb.size === 0) return 0;
  let common = 0;
  for (const gram of ta) if (tb.has(gram)) common++;
  return common / (ta.size + tb.size - common);
};

const coverage = (wanted: string[], candidates: string[]): number => {
  if (candidates.length === 0) return 0;
  let total = 0;
  for (const word of wanted) {
    let best = 0;
    for (const candidate of candidates) {
      const value = word === candidate ? 1 : similarity(word, candidate);
      if (value > best) best = value;
      if (best === 1) break;
    }
    if (best >= TOKEN_FLOOR) total += best;
  }
  return total / wanted.length;
};

export const score = (
  keywords: string,
  title: string,
  description = '',
): number => {
  const wanted = tokens(keywords);
  if (wanted.length === 0) return 0;
  const titleTokens = tokens(title);
  const cover = Math.max(
    coverage(wanted, titleTokens),
    coverage(wanted, tokens(description)) * DESCRIPTION_WEIGHT,
  );
  const phrase = similarity(wanted.join(' '), titleTokens.join(' '));
  return Math.min(1, Math.max(0, 0.75 * cover + 0.25 * phrase));
};

export type MatchableAlert = {
  keywords: string;
  matchLevel: WantedAlertMatchLevel;
  categoryId: string | null;
  minPrice: number | null;
  maxPrice: number | null;
  conditions: string[];
  dealTypes: string[];
  areaCode: string | null;
  areaLevel: 'province' | 'ward' | null;
  createdAt: Date;
};

export type MatchableListing = {
  title: string;
  description: string;
  price: number;
  condition: string;
  allowSale: boolean;
  allowExchange: boolean;
  categoryId: string | null;
  provinceCode: string | null;
  wardCode: string | null;
  createdAt: Date;
};

/** Bộ lọc cứng: phải qua hết mới chấm điểm từ khoá */
export const passesFilters = (
  alert: MatchableAlert,
  listing: MatchableListing,
): boolean => {
  if (listing.createdAt < alert.createdAt) return false;
  if (alert.categoryId && alert.categoryId !== listing.categoryId) return false;
  if (alert.dealTypes.length > 0) {
    const sale = alert.dealTypes.includes('buy') && listing.allowSale;
    const exchange = alert.dealTypes.includes('exchange') && listing.allowExchange;
    if (!sale && !exchange) return false;
  }
  // Tin chỉ đổi không có giá bán thật, bỏ qua lọc giá
  const priced = listing.allowSale;
  if (priced && alert.minPrice != null && listing.price < alert.minPrice) return false;
  if (priced && alert.maxPrice != null && listing.price > alert.maxPrice) return false;
  if (alert.conditions.length > 0 && !alert.conditions.includes(listing.condition)) {
    return false;
  }
  if (alert.areaCode) {
    const code = alert.areaLevel === 'ward' ? listing.wardCode : listing.provinceCode;
    if (code !== alert.areaCode) return false;
  }
  return true;
};

/** Điểm nếu tin khớp thông báo, null nếu không khớp */
export const matchListing = (
  alert: MatchableAlert,
  listing: MatchableListing,
): number | null => {
  if (!passesFilters(alert, listing)) return null;
  const value = score(alert.keywords, listing.title, listing.description);
  return value >= MATCH_THRESHOLDS[alert.matchLevel] ? value : null;
};
