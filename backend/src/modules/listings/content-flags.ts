import { AppError } from '../../common/errors/app-error.js';
/*
 * Gắn cờ nội dung tin đăng cho admin: chỉ đánh dấu để duyệt kỹ hơn, không tự từ chối tin (người đăng được cảnh báo trước).
 * Quét tiêu đề và mô tả lúc admin mở hàng chờ, nên đổi luật ở đây là áp dụng ngay cho mọi tin.
 */

export type FlagCode = 'CONTACT' | 'LINK' | 'BANNED';
export type ContentFlag = { code: FlagCode; match: string };

/** Một từ / cụm từ đứng riêng (không dính chữ hay số khác), không phân biệt hoa thường */
const word = (pattern: string) => new RegExp(`(?<![\\p{L}\\p{N}])(?:${pattern})(?![\\p{L}\\p{N}])`, 'iu');

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
    word('súng|đạn|vũ khí|vu khi|thuốc nổ|thuoc no|pháo|phao no|dao găm'),
    word('hàng giả|hang gia|hàng nhái|hang nhai|hàng fake|fake|super fake|replica|rep 1:1'),
    word('thuốc lá điện tử|thuoc la dien tu|vape|pod'),
    word('cá độ|ca do|cờ bạc|co bac|lô đề|lo de'),
    word('bán tài khoản ngân hàng|thẻ tín dụng|the tin dung|cccd giả'),
  ],
};

/** Cờ của nội dung, mỗi loại một cờ kèm đoạn khớp đầu tiên (để admin thấy vì sao bị gắn) */
export function contentFlags(...texts: (string | null | undefined)[]): ContentFlag[] {
  const text = texts.filter(Boolean).join('\n').normalize('NFC');
  const flags: ContentFlag[] = [];
  for (const [code, patterns] of Object.entries(RULES) as [FlagCode, RegExp[]][]) {
    for (const pattern of patterns) {
      const found = text.match(pattern);
      if (found) {
        flags.push({ code, match: found[0].trim() });
        break;
      }
    }
  }
  return flags;
}

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
