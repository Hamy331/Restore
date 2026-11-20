import type { Content } from '../assistant.type.js';

export const normalize = (text: string) => text.normalize('NFD').replace(/\p{M}/gu, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
export const CLARIFY = 'Mình chưa hiểu. Bạn muốn tìm sản phẩm hay hỏi về ReStore?';
export const SCOPE = 'Mình hỗ trợ tìm sản phẩm và giải đáp về ReStore.';
export const NO_EVIDENCE = 'Mình chưa có đủ dữ liệu đã kiểm chứng để trả lời. Bạn thử nói rõ sản phẩm hoặc nội dung ReStore cần tìm nhé.';

/** Conservative rules: unknown short words and misspellings still reach the model. */
export function inputReply(message: string, hasHistory: boolean): string | undefined {
  const q = normalize(message).trim();
  const question = q.replace(/[?!.…]+$/, '').trim().replace(/\s+/g, ' ');
  const vietnameseRequest = /^(?:(?:ban|bot|restore|tro ly|ai) )?(?:(?:co the|co biet|co|biet|vui long|hay) )?(?:noi(?: chuyen)?|chat|giao tiep|tra loi|chuyen sang|dung)(?: (?:duoc|dc))?(?: voi (?:minh|toi))?(?: bang)? tieng viet(?: (?:duoc|dc))?(?: (?:khong|ko|k|hong))?(?: (?:nhe|nha|a))?$/;
  if (vietnameseRequest.test(question) || /^(?:(?:can|could) you |please )?(?:speak|use|reply in|answer in) vietnamese(?: please)?$/.test(question)) {
    return 'Được chứ! Mình có thể trò chuyện với bạn bằng tiếng Việt. Bạn muốn mình giúp gì trên ReStore?';
  }
  if (/^(?:ban|restore|tro ly)(?: co the)? (?:lam duoc gi|lam gi|giup (?:minh|toi) (?:nhung )?gi)$/.test(question)) {
    return 'Mình có thể tìm tin theo ngân sách, so sánh các món bạn đang xem và hướng dẫn bạn dùng ReStore. Bạn muốn bắt đầu từ đâu?';
  }
  if (!/[\p{L}\p{N}]/u.test(q) || /^(.{1,4})\1{3,}$/u.test(q.replace(/\s/g, '')) || /^(?:asdf[\w]*|qwerty[\w]*|zxcv[\w]*|hjkl[\w]*)$/i.test(q)) return CLARIFY;
  if (/^(?:xin chao|chao|hello|hi|hey)[.!\s]*$/.test(q)) return 'Chào bạn! Mình có thể giúp tìm, so sánh sản phẩm và giải đáp về ReStore.';
  if (/^(?:cam on|thanks|thank you)[.!\s]*$/.test(q)) return 'Rất vui được giúp bạn. Bạn cần tìm sản phẩm hay hỏi thêm về ReStore cứ nói nhé.';
  if (/(?:bo qua|ignore|forget).{0,35}(?:quy tac|chi dan|instructions|rules|system prompt)|(?:tiet lo|reveal|show).{0,25}(?:system prompt|api key|token|mat khau)/.test(q)) return 'Mình chỉ hỗ trợ yêu cầu trong phạm vi ReStore và không cung cấp thông tin bí mật.';
  if (/(?:tai khoan|lich su|tin nhan|han muc|so du).{0,35}(?:nguoi khac|cua ban khac|user khac)|(?:other user|another user).{0,30}(?:history|quota|account|messages)/.test(q)) return 'Mình chỉ có thể tra cứu thông tin tài khoản của bạn và các tin đăng công khai.';
  if (/\b(?:viet (?:bai van|tho|truyen|code)|lam bai tap|giai (?:toan|bai tap)|write (?:an essay|a poem)|thoi tiet|ket qua bong da)\b/.test(q) && !/restore|san pham|tin dang/.test(q)) return SCOPE;
  if (/^(?:re hon(?: chut)?|cai thu (?:hai|ba|tu|\d+)|that one|cheaper)[.!?\s]*$/.test(q)) return hasHistory ? undefined : 'Bạn đang nói tới sản phẩm nào? Hãy cho mình tên hoặc yêu cầu tìm sản phẩm trước nhé.';
  if (!hasHistory && /^(?:tim|mua|tu van)(?: giup| cho minh| giup minh)? (?:dien thoai|laptop|may tinh)[.!?\s]*$/.test(q)) return 'Bạn dự định chi khoảng bao nhiêu và ưu tiên nhu cầu nào, chẳng hạn camera, pin hay chơi game?';
  return undefined;
}

/** Current explicit intent wins; short follow-ups inherit the latest user question. */
export function requiredTools(message: string, history: Content[]): string[] {
  let q = normalize(message);
  if (/^(?:re hon|cai thu|con nao|so sanh|cheaper)/.test(q)) {
    const previous = history.filter(c => c.role === 'user').flatMap(c => c.parts.filter(p => p.text).map(p => p.text!)).slice(-3).join(' ');
    q += ' ' + normalize(previous);
  }
  const tools: string[] = [];
  if (/han muc|goi (?:hien tai|cua (?:toi|minh|ban))|con (?:may|bao nhieu).{0,25}(?:tin|nhap|luot)|quota/.test(q)) tools.push('my_quota');
  if (/chinh sach|quy dinh|hoan tien|doi tra|tra hang|bao hanh|dieu khoan|gia goi|\bphi\b|huong dan|cach (?:dang tin|bao cao|doi|mua)|policy|refund/.test(q)) tools.push('search_knowledge');
  if (/\b(?:tim|mua|gia|san pham|so sanh|dien thoai|laptop|iphone|samsung|re hon|cai thu|listing)\b/.test(q) && !tools.includes('my_quota') && !tools.includes('search_knowledge')) tools.push('listings');
  return tools;
}

export function containsInstruction(text: string): boolean {
  return /(?:ignore|forget|bo qua).{0,35}(?:instructions|rules|system|quy tac|chi dan)|(?:system|developer)\s*[:：]|(?:send|gui|tiet lo).{0,30}(?:api.?key|token|password)|<\/?(?:system|tool|developer)>/.test(normalize(text));
}
