import { AppError } from '../../common/errors/app-error.js';

/*
 * Gắn cờ nội dung tin đăng cho admin: chỉ đánh dấu để duyệt kỹ hơn, không tự từ chối tin (người đăng được cảnh báo trước).
 * Cờ hiển thị cho admin quét lại lúc mở hàng chờ (đổi luật là áp dụng ngay); bộ lọc "chỉ tin bị gắn cờ" dùng
 * cột flagged ghi lúc gửi duyệt, nên đổi luật chỉ áp cho tin gửi sau đó.
 */

export type FlagCode = 'CONTACT' | 'LINK' | 'BANNED';
export type ContentFlag = { code: FlagCode; match: string };

/**
 * Một từ / cụm từ đứng riêng (không dính chữ hay số khác), không phân biệt hoa thường.
 * Khoảng trắng trong cụm từ khớp cả dấu chấm, gạch hoặc viết liền ("ma túy", "ma.túy", "matúy").
 */
const word = (pattern: string) =>
  new RegExp(`(?<![\\p{L}\\p{N}])(?:${pattern.replaceAll(' ', '[\\s._*-]*')})(?![\\p{L}\\p{N}])`, 'iu');

/** Ký tự vô hình chèn giữa chữ để lách bộ lọc */
const INVISIBLE = /[­​-‍⁠﻿]/gu;
/** Chữ cái tách rời từng chữ: "r.ư.ợ.u", "m a t u y" (từ 3 chữ trở lên) */
const SPELLED = /(?<![\p{L}\p{N}])\p{L}(?![\p{L}\p{N}])(?:[\s._*+-]+\p{L}(?![\p{L}\p{N}])){2,}/gu;
/** Chữ có số / ký hiệu thay chữ cái: "c4n s4", "r0u", "v@pe" */
const MIXED = /[\p{L}\d@$]*\p{L}[\p{L}\d@$]*/gu;
const LEET: Record<string, string> = { 0: 'o', 1: 'i', 3: 'e', 4: 'a', 5: 's', 7: 't', '@': 'a', $: 's' };

/** Bản "gỡ lách" của nội dung: dính chữ tách rời, đổi số / ký hiệu về chữ; khớp thêm trên bản này */
const unmask = (text: string) =>
  text
    .replace(SPELLED, (run) => run.replace(/[^\p{L}]/gu, ''))
    .replace(MIXED, (token) => token.replace(/[013457@$]/g, (c) => LEET[c]));

const RULES: Record<FlagCode, RegExp[]> = {
  /** Số điện thoại Việt Nam (có thể chèn dấu cách, chấm, gạch) hoặc rủ liên hệ ngoài ứng dụng */
  CONTACT: [
    /(?<!\d)(?:\+?84|0)[ .-]?[35789](?:[ .-]?\d){8}(?!\d)/u,
    word('zalo|sđt|sdt|hotline|viber|telegram|whatsapp'),
  ],
  /** Đường dẫn web, tên miền hoặc link mạng xã hội */
  LINK: [
    /https?:\/\/\S+|www\.\S+/iu,
    word('[a-z0-9-]+\\.(?:com|vn|net|org|info|me|io|shop|store|xyz|link)(?:\\/\\S*)?'),
  ],
  /** Hàng cấm hoặc hàng giả theo quy định đăng tin (có dấu và không dấu) */
  BANNED: [
    word('ma túy|ma tuý|ma tuy|cần sa|can sa|thuốc lắc|thuoc lac|cỏ mỹ'),
    word('ketamine?|kẹo ke|keo ke|heroin|cocaine|methamphetamine|bóng cười|bong cuoi|khí cười|nước vui|nuoc vui'),
    word('thuốc kích dục|thuoc kich duc|thuốc mê|cồn công nghiệp|con cong nghiep|methanol|metanol'),
    // Rượu bia; bỏ qua đồ dùng đựng rượu (tủ rượu, ly rượu...). "bia" đứng riêng dễ nhầm "bìa" viết không dấu
    word('(?<!(?:tủ|tu|kệ|ke|ly|cốc|coc|giá\\sđể|gia\\sde|bình\\sngâm|binh\\sngam|hũ\\sngâm|hu\\sngam)\\s)(?:rượu|ruou)'),
    word('vodka|whiske?y|soju|cognac|thùng bia|thung bia|bia lon|bia chai|bia tươi|bia tuoi'),
    word('thuốc lá|thuoc la|xì gà|xi ga|cigar'),
    word('súng|đạn|vũ khí|vu khi|thuốc nổ|thuoc no|pháo|phao no|dao găm'),
    word('hàng giả|hang gia|hàng nhái|hang nhai|hàng fake|fake|super fake|replica|rep 1:1'),
    word('thuốc lá điện tử|thuoc la dien tu|vape|pod'),
    word('cá độ|ca do|cờ bạc|co bac|lô đề|lo de'),
    word('bán tài khoản ngân hàng|thẻ tín dụng|the tin dung|cccd giả'),
  ],
};

/** Từ admin thêm (bảng BannedTerm); chỉ thêm vào CONTACT và BANNED, luật có sẵn ở trên không đổi */
export type ExtraTermCode = 'CONTACT' | 'BANNED';
const extra: Partial<Record<FlagCode, RegExp>> = {};
const escape = (term: string) => term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Thay danh sách từ admin thêm (gọi khi khởi động, định kỳ và sau mỗi lần admin sửa) */
export function setExtraTerms(terms: { term: string; code: ExtraTermCode }[]) {
  for (const code of ['CONTACT', 'BANNED'] as const) {
    const list = terms.filter((t) => t.code === code).map((t) => escape(t.term.normalize('NFC')));
    if (list.length) extra[code] = word(list.join('|'));
    else delete extra[code];
  }
}

/** Cờ của nội dung, mỗi loại một cờ kèm đoạn khớp đầu tiên (để admin thấy vì sao bị gắn) */
export function contentFlags(...texts: (string | null | undefined)[]): ContentFlag[] {
  const text = texts.filter(Boolean).join('\n').normalize('NFC').replace(INVISIBLE, '');
  const unmasked = unmask(text);
  const sources = unmasked === text ? [text] : [text, unmasked];
  const flags: ContentFlag[] = [];
  for (const [code, patterns] of Object.entries(RULES) as [FlagCode, RegExp[]][]) {
    for (const pattern of [...patterns, ...(extra[code] ? [extra[code]] : [])]) {
      const found = sources.map((source) => source.match(pattern)).find(Boolean);
      if (found) {
        flags.push({ code, match: found[0].trim() });
        break;
      }
    }
  }
  return flags;
}

/** Nội dung có ít nhất một cờ; lưu vào Listing.flagged / ListingRevision.flagged lúc gửi duyệt */
export const isFlagged = (title: string, description: string) => contentFlags(title, description).length > 0;

/**
 * Cảnh báo lúc đăng / sửa tin: nội dung bị gắn cờ thì 409 CONTENT_FLAGGED { details: { flags } } để người dùng
 * tự sửa trước. Người dùng vẫn muốn gửi thì gửi lại với acceptFlags: true, tin vào hàng chờ kèm cờ như cũ.
 */
export function assertNoContentFlags(acceptFlags: boolean, title: string, description: string) {
  if (acceptFlags) return;
  const flags = contentFlags(title, description);
  if (flags.length) {
    throw new AppError(409, 'CONTENT_FLAGGED',
      'Tin có số điện thoại, đường link hoặc từ ngữ về hàng cấm nên có thể bị từ chối. Sửa lại để được duyệt nhanh hơn.',
      undefined, { flags });
  }
}
