import 'dotenv/config';
import { prisma } from '../src/lib/prisma.js';
import { configuredProvider } from '../src/modules/ai/assistant/services/gemini.provider.js';
import { retrieve } from '../src/modules/ai/rag/services/rag.service.js';

// Judgments apply to the three bootstrap guides. Re-label if the corpus changes.
const groups = [
  { expected: 'restore-bootstrap-drafts-v1', queries: [
    'Chưa chụp hình sản phẩm thì giữ tin để mai làm tiếp được không?',
    'gui tin de duyet can dien nhung gi',
    'AI viết xong mô tả thì tin đã đăng bán luôn chưa?',
    'Đề xuất bản nháp hết hạn thì làm sao?',
  ] },
  { expected: 'restore-bootstrap-quota-v1', queries: [
    'Làm sao biết gói của mình còn mấy lượt?',
    'tro ly co chuyen credit duoc khong',
    'Vừa kiểm tra còn lượt, lúc gửi có kiểm tra lại không?',
    'Trợ lý có thể thanh toán bằng số dư giúp tôi không?',
  ] },
  { expected: 'restore-bootstrap-search-v1', queries: [
    'Nhờ trợ lý so sánh ba món đồ theo tình trạng và giá thế nào?',
    'tim dien thoai trong ngan sach bang cach nao',
    'Nếu tìm hàng không ra thì nên đổi câu hỏi ra sao?',
    'Tôi có thể thu hẹp hãng ở câu hỏi tiếp theo không?',
  ] },
  { expected: null, queries: [
    'Lịch tàu cao tốc đi Côn Đảo ngày mai?',
    'Công thức làm bánh mì nguyên cám?',
    'Cách trồng hoa hồng ngoài ban công?',
  ] },
];

if (!process.argv.includes('--live')) {
  console.log(JSON.stringify({ mode: 'preview', groups }, null, 2));
} else {
  const provider = configuredProvider();
  let labeled = 0, hits = 0, reciprocalRanks = 0, negatives = 0, empty = 0;
  try {
    for (const { expected, queries } of groups) {
      for (const query of queries) {
        const results = await retrieve(query, provider, AbortSignal.timeout(30000));
        const ids = [...new Set(results.map(source => source.id))].slice(0, 3);
        if (expected) {
          labeled++;
          const rank = ids.indexOf(expected) + 1;
          if (rank > 0) { hits++; reciprocalRanks += 1 / rank; }
        } else {
          negatives++;
          if (ids.length === 0) empty++;
        }
        console.log(JSON.stringify({ query, expected, retrieved: ids }));
      }
    }
    console.log(JSON.stringify({ labeled, negatives, recallAt3: hits / labeled,
      mrrAt3: reciprocalRanks / labeled, noAnswerEmptyRate: empty / negatives }));
  } finally {
    await prisma.$disconnect();
  }
}
