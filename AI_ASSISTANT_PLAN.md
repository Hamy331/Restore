# ReStore AI assistant

## Cập nhật 2026-11-18: Conversation state và slot filling

Phạm vi hiện hành: Assistant chỉ đọc dữ liệu, không tạo/lưu tin nháp. Các mục đề xuất/xác nhận nháp bên dưới là lịch sử thiết kế, không còn áp dụng.

Áp dụng mọi danh mục đang hoạt động từ database; đọc tên và key/nhãn thuộc tính từ Category.metadata, không cố định theo điện thoại/Samsung.

1. Thêm AiConversation.state có version: intent, nhu cầu, câu hỏi đang chờ, thứ tự kết quả, lựa chọn, số lần không hiểu. Migration bổ sung, không reset dữ liệu.
2. Schema Zod kiểm tra state và trích xuất có cấu trúc. Undefined giữ nguyên, null bỏ ràng buộc; thuộc tính theo danh mục được hợp nhất theo key. Đổi nhu cầu sản phẩm xóa điều kiện cũ không được lặp lại.
3. Hàm cập nhật state thuần; tách trích xuất, quyết định hội thoại, thực thi tìm hàng và lưu dữ liệu. Câu ngân sách/số thứ tự rõ ràng xử lý trực tiếp; câu phức tạp dùng Gemini JSON có schema.
4. Chỉ hỏi thông tin cần thiết, một câu mỗi lượt. Không bắt điền đủ; hỗ trợ tìm luôn, không giới hạn, đổi ngân sách, bỏ hãng, tiếp tục tìm sau khi hỏi hạn mức/chính sách.
5. Chọn theo thứ tự kết quả đã hiển thị; tìm rẻ hơn phải đọc lại giá tin được chọn. Tin ẩn/xóa không dùng dữ liệu cũ. Không tự nới bộ lọc khi không có kết quả.
6. Ba lượt không hiểu liên tiếp chuyển sang lựa chọn nhanh; giữ nhu cầu hợp lệ trước đó. Câu trả lời có nghĩa đặt lại bộ đếm. Bắt đầu lại xóa nhu cầu, giữ lịch sử và giới hạn tần suất.
7. State và câu trả lời commit cùng giao dịch, kiểm tra lease; retry không cập nhật lặp. Không giữ giao dịch khi chờ AI. Lỗi công cụ, hủy hoặc lỗi ghi không làm tiến state.
8. Flutter đọc suggestions tùy chọn, chỉ bật lựa chọn ở câu trả lời mới nhất khi không bận/retry. JSON, SSE và lịch sử dùng cùng model.
9. Giá/hãng/danh mục là bộ lọc chính xác hiện có. Khu vực/tình trạng/thuộc tính/nhu cầu là tín hiệu tìm theo nội dung; không hứa khớp tuyệt đối. Chi tiết và so sánh chỉ trình bày trường thực tế từ công cụ.
10. Kiểm thử nhiều lượt, sửa/bỏ điều kiện, mọi loại danh mục, số thứ tự, hỏi lại, dữ liệu lỗi, retry, khôi phục, lỗi công cụ/commit và hủy yêu cầu. Chạy backend typecheck/tests và Flutter analyze/tests. Đánh giá Gemini thật và độ trễ/chi phí trên môi trường thử trước rollout.

Triển khai database: dừng backend đang chạy để giải phóng Prisma engine nếu bị khóa; trong backend chạy `npx prisma generate`, `npx prisma migrate deploy`, rồi khởi động lại backend. Không dùng migrate reset. Migration chưa được tự áp dụng lên database cấu hình.

Ngày bắt đầu: 2026-11-08. Provider: Gemini. Cùng repo Restore, cùng backend và auth hiện tại.

## Bản đầu

- Chat tiếng Việt, lịch sử hội thoại thuộc người đăng nhập; giữ ngữ cảnh câu tiếp nối.
- Function calling: tìm tin đang bán, đọc chi tiết công khai để so sánh, đọc hạn mức của chính mình, tìm tài liệu, đề xuất bản nháp.
- Người dùng xem và xác nhận bản nháp trước khi lưu. Không đăng tin, thanh toán, tiêu credit hoặc gửi tin nhắn thay người dùng.
- RAG chỉ đọc KnowledgeDocument đang active và đã index. Embedding có phiên bản; tài liệu sửa/xóa/tắt không tiếp tục được truy xuất từ chỉ mục cũ.
- Thay màn hình AI demo Flutter bằng API thật, có trạng thái đang gửi, lỗi, thử lại, nguồn tài liệu và thẻ tin đăng.
- Kiểm thử giới hạn công cụ, quyền sở hữu, ngữ cảnh, timeout, retry và xác nhận lặp.

## Cấu trúc

`backend/src/modules/ai/assistant/{routes,controllers,services,repositories}`: chat, provider Gemini, tool registry, guardrails, hành động chờ xác nhận.

`backend/src/modules/ai/rag/{routes,controllers,services,repositories}`: quản lý chỉ mục embedding, chunking, truy xuất và nguồn tài liệu.

Trong `rag/services/`, tách từng quá trình: `ingestion.service` → `chunking.service` → `embedding.service` → `indexing.service`; lúc hỏi dùng `retrieval.service` → `ranking.service` → `context.service`. `rag.service` chỉ export các entry point. System prompt và vòng gọi Gemini ở assistant.

Frontend: `modules/ai/{bloc,models,repositories,views}`. Dùng ApiClient hiện có để giữ luồng refresh token.

## Model và dữ liệu

- Chat: `gemini-3.5-flash-lite`, theo yêu cầu đổi model mới nhất của người dùng; thay được qua biến môi trường.
- Embedding: `gemini-embedding-2`, 768 chiều. Model này không nhận taskType; không trộn vector từ các model khác nhau.
- Theo thay đổi người dùng đã chốt: vector lưu trên **Qdrant Cloud**, collection 768 chiều/Cosine. PostgreSQL giữ tài liệu/chunk, phiên bản, trạng thái index và hàng đợi xóa vector. Không dùng Qdrant local, pgvector hay SQL cosine scan trong runtime. Cột vector SQL cũ được giữ lại để migration không xóa dữ liệu; record mới để mảng rỗng.
- Hạn mức lấy từ commerce service hiện có. Nghiệp vụ ví credit trong đề xuất chưa có backend nên AI phải nói chưa hỗ trợ, không tự lấy con số từ đề xuất làm chính sách đang áp dụng.

## Guardrails

- Xác thực, quyền và userId lấy từ server; schema công cụ strict; không có SQL, URL fetch hay công cụ quản trị tùy ý.
- Tài liệu, nội dung tin và lời người dùng là dữ liệu không đáng tin, không được thay system instruction.
- Công cụ đọc chỉ trả dữ liệu cần thiết. Nội dung AI hiển thị dạng text, không chạy HTML hay tự mở URL.
- Giới hạn số vòng gọi model, số công cụ, chiều dài input/context/output và timeout; hạn mức request theo tài khoản lưu DB dùng chung giữa các instance.
- Request ID chống gửi trùng; khóa hội thoại; xác nhận draft gắn với người dùng, nội dung cố định, hết hạn và transaction quota.
- Không ghi API key hoặc nội dung chat vào log. Tắt AI khi chưa cấu hình; lỗi provider không biến thành câu trả lời giả.

## Triển khai và đánh giá

1. Thêm migration mới, cấu hình mẫu, provider và hai module backend.
2. Nối Flutter, bỏ toàn bộ kết quả giả trong màn hình AI.
3. Chạy TypeScript, backend tests, Flutter analyze/tests; dùng database test local riêng cho API tests.
4. Ghi kết quả, lệnh chạy, giới hạn còn lại trong RESTORE_HANDOFF.md.

Đã được người dùng xác nhận triển khai trên Supabase đang cấu hình. Hai migration AI đã áp dụng; đã thử Gemini và Qdrant Cloud thật. Cần hoàn tất các ca đánh giá model đang bị hạn mức Gemini chặn và bổ sung tài liệu nghiệp vụ được duyệt.

## Sau bản đầu

Ảnh đầu vào, streaming token, Redis cache/rate limiter, tác vụ credit/payment chỉ nối khi nghiệp vụ thật sẵn sàng. Không coi các phần này đã triển khai trong MVP. Qdrant Cloud đã thay thế kế hoạch pgvector.

## Kết quả triển khai 08/11/2026

- Đã triển khai backend assistant/RAG, migration, tích hợp Flutter, guardrails, kiểm thử và cập nhật handoff.
- Sau thay đổi Qdrant: TypeScript build đạt, 76 unit tests backend và 33 API tests đạt trên PostgreSQL local. Flutter không đổi trong bước Qdrant; kết quả lần trước là analyze đạt và 108 tests đạt.
- Đã có lệnh `npm run ai:eval` với 7 tình huống tiếng Việt, chỉ chạy Gemini thật khi bật `AI_LIVE_EVAL=true`.
- Đã có cấu hình Gemini/Qdrant Cloud và bật AI_ENABLED trong backend/.env; không đưa secrets vào Git. Hai migration đã áp dụng trên Supabase theo xác nhận của người dùng. Backend đã khởi động ở port 3000.
- Qdrant Cloud ghi/tìm/xóa vector thử đạt. Live RAG với Gemini embedding và kiểm tra loại tài liệu inactive đạt; SQL fixture chỉ nằm trong DB local và vector thử đã được dọn.
- Live Gemini đạt 4/7 tình huống: tìm theo giá, câu tiếp nối, quota và tìm tài liệu. Ba tình huống draft/injection/credit chưa hoàn tất vì AI_PROVIDER_RATE_LIMIT, kể cả khi thử lại cách nhau 60 giây. Không tính các ca này là đạt.
- Supabase hiện chưa có KnowledgeDocument active và đã index, nên chưa có tài liệu nghiệp vụ thật để nạp RAG. Chưa commit/push.
- Quy trình bật tính năng và giới hạn MVP ghi trong `backend/src/modules/ai/README.md` và mục 13 của `RESTORE_HANDOFF.md`.

### Sau khi đổi model chat sang Flash-Lite

Đã cấu hình `gemini-3.5-flash-lite` và backend nạp lại cấu hình. TypeScript build và 6 test orchestrator/provider đạt. Ba live eval từng bị quota chặn đã đạt trên model mới: draft chờ xác nhận, prompt injection và hành động credit chưa hỗ trợ. Bốn tình huống còn lại chưa chạy lại trên Flash-Lite; không gộp kết quả của hai model thành một bộ 7/7. Xem mục 15 trong handoff.

### Hybrid RAG và tài liệu khởi tạo — 08/11/2026

- Đã thêm hai nhánh tìm độc lập: dense Gemini + sparse TF-IDF, gộp bằng Qdrant RRF. Keyword không còn chỉ xếp lại các kết quả dense. Sparse chạy tại backend với tokenizer tiếng Việt chuẩn hóa dấu/case, Qdrant tính IDF. Đây không phải BM25.
- Cloud 1.19.2 đã được bổ sung `lexical_v1` vào collection cũ, giữ dense 768/Cosine. Không cần migration PostgreSQL mới. Kiểm tra phiên bản nguồn/quyền vẫn thực hiện qua PostgreSQL sau retrieval; không áp cutoff cosine lên điểm RRF.
- Đã nạp 3 tài liệu hướng dẫn từ code trong `backend/knowledge/bootstrap.json` theo yêu cầu người dùng, mỗi tài liệu một chunk. Ba truy vấn đều trả đúng nguồn ở vị trí đầu. Nội dung không đặt số quota, giá hay tỷ lệ credit giả; thông tin này vẫn lấy từ nghiệp vụ thật.
- Live Cloud test chứng minh sparse tìm được tài liệu mà dense cố ý bỏ sót; truy vấn không liên quan không có kết quả. Live RAG kiểm tra loại tài liệu inactive đạt, API AI tests 11/11 đạt. Kết quả build/unit cuối xem mục 16 trong handoff.
- Phạm vi hybrid là kho kiến thức RAG. Search listing vẫn dùng service/SQL hiện có; chưa có semantic/hybrid index cho listing.
- Việc tiếp theo: tài liệu nghiệp vụ chính thức; benchmark nhiều câu hỏi và câu không có đáp án để tinh chỉnh retrieval; lịch sử hội thoại phía Flutter; streaming. Chưa commit/push.

### Bổ sung theo yêu cầu: listing và streaming

- Hybrid RAG vẫn giữ; search_listings được nối thêm hybrid listing collection riêng. Tạo AiListingIndex, trigger vô hiệu/queue xóa, job đồng bộ theo batch; kiểm tra lại giá/hãng/category/visibility/hash trong SQL trước khi trả kết quả.
- Stream Gemini thật qua SSE, có trạng thái công cụ, delta tạm và done sau commit. Flutter có Fetch adapter riêng cho web, giữ auth refresh; lỗi/ngắt xóa partial và retry cùng request ID.
- Tách repository/service/job/helper, hằng kỹ thuật dùng tên rõ, batch/interval lấy env, trạng thái UI qua l10n. Không hardcode dữ liệu nghiệp vụ.
- Migration listing đã kiểm thử trên PostgreSQL test local và triển khai Supabase theo quyền triển khai AI đã cấp. Kết quả xác minh cuối nằm trong mục 17 handoff; các dòng ở mục trước nói listing chưa hybrid/streaming chưa làm đã được thay thế bởi cập nhật này.
