# Checklist thiết kế UI Admin ReStore

Kế hoạch: `tasks/plan.md`. Đây là task thiết kế tương lai, chưa phải các chức năng đã được lập trình.
Artifact dự kiến: các frame ADM trong Figma ReStore hiện có khi người dùng yêu cầu thực hiện; bảng mapping và ghi chú bàn giao. Chưa xác định file code vì chưa chọn nền tảng admin.

## T1 — Thống nhất trạng thái và khung admin
- [ ] Map yêu cầu 4.1.2 với các use case; ghi rõ các xung đột đã nêu trong plan.
- [ ] Dựng sidebar, header, bảng, form, modal, badge và luồng truy cập admin ADM-00.
- [ ] Thể hiện desktop/tablet, không có quyền và hết phiên.
Phụ thuộc: không. Phạm vi: vừa. Kiểm tra: đi qua menu bằng chuột/bàn phím; mỗi mục có đích đến; trạng thái phù hợp vai trò.

## T2 — Kiểm duyệt tin
- [ ] ADM-02 có tìm kiếm, lọc, phân trang và các tab trạng thái.
- [ ] ADM-03 có đủ ảnh, nội dung, chủ tin, lịch sử và hành động theo trạng thái.
- [ ] Duyệt/yêu cầu sửa/từ chối/gỡ tin có kết quả, lý do khi cần và tình huống đã được xử lý bởi admin khác.
Phụ thuộc: T1. Phạm vi: vừa. Kiểm tra: prototype từ hàng đợi tới quyết định rồi quay lại giữ bộ lọc; thiếu lý do không thể xác nhận.

## Checkpoint A
- [ ] Luồng kiểm duyệt khớp spec, trạng thái và quyền; các xung đột có ghi chú.
- [ ] Rà soát prototype kiểm duyệt trước khi dùng lại thành phần quyết định.

## T3 — Quản lý người dùng
- [ ] ADM-04 tìm kiếm/lọc và mở đúng hồ sơ.
- [ ] ADM-05 hiển thị hồ sơ, tin, báo cáo và lịch sử xử lý.
- [ ] Cảnh báo/đình chỉ/cấm có lý do, thời hạn nếu áp dụng và xác nhận.
Phụ thuộc: T1. Phạm vi: vừa. Kiểm tra: prototype đình chỉ có thời hạn; dữ liệu không hợp lệ không được lưu; kết quả xuất hiện trong lịch sử.

## T4 — Xử lý báo cáo
- [ ] ADM-06 phân biệt báo cáo tin và người dùng, có lọc trạng thái/lý do/ngày.
- [ ] ADM-07 hiển thị bằng chứng, đối tượng và liên kết sang trang chi tiết tương ứng.
- [ ] Hành động phù hợp đối tượng, kết luận bắt buộc và kết quả thông báo được mô tả.
Phụ thuộc: T2, T3. Phạm vi: vừa. Kiểm tra: prototype báo cáo tin → gỡ tin; báo cáo người dùng → cảnh báo; bác báo cáo → đóng với kết luận.

## Checkpoint B
- [ ] Báo cáo và hồ sơ dùng thống nhất nhãn trạng thái, lý do và lịch sử.
- [ ] Các luồng lỗi/trống/xung đột thao tác không hiển thị thành công giả.

## T5 — Danh mục và tình trạng
- [ ] ADM-08 có hai tab, danh sách và form thêm/sửa.
- [ ] Ngừng sử dụng có xác nhận và mô tả ảnh hưởng đến tin hiện có theo quy tắc được chốt.
- [ ] Form có kiểm tra trường bắt buộc và thông báo lỗi.
Phụ thuộc: T1. Phạm vi: nhỏ. Kiểm tra: prototype thêm/sửa/ngừng danh mục đang được dùng.

## T6 — Tổng quan
- [ ] ADM-01 có KPI với định nghĩa và khoảng thời gian rõ ràng.
- [ ] Tin chờ duyệt và báo cáo mới mở đúng màn hình tương ứng.
- [ ] Biểu đồ và KPI có trạng thái dữ liệu trống, lỗi và đang tải riêng.
Phụ thuộc: T2, T4; chỉ số Boost hoàn thiện sau T9. Phạm vi: nhỏ. Kiểm tra: các lối tắt giữ bộ lọc đích phù hợp; không nhầm phí Boost với giá trị giao dịch mua bán.

## T7 — Gói Boost
- [ ] ADM-10 có tên, thời lượng, giá, ưu tiên hiển thị và trạng thái.
- [ ] Thêm/sửa/bật/tắt có validation và xác nhận phù hợp.
- [ ] Ghi rõ ảnh hưởng với gói đã mua theo chính sách được chốt.
Phụ thuộc: T1. Phạm vi: nhỏ. Kiểm tra: giá/thời lượng sai hiện lỗi; xem trước danh sách sau lưu và sau ngừng gói.

## T8 — Giao dịch Boost
- [ ] ADM-11 có tìm kiếm/lọc và drawer mở đúng giao dịch.
- [ ] Thanh toán và kích hoạt Boost dùng hai trạng thái riêng.
- [ ] Có trạng thái chờ xác nhận, thất bại, hủy và đã trả tiền nhưng chưa kích hoạt.
Phụ thuộc: T7. Phạm vi: nhỏ. Kiểm tra: đối chiếu chi tiết với dòng giao dịch; không có nút tự đánh dấu thanh toán thành công.

## T9 — Thống kê Boost
- [ ] ADM-09 có thống kê và biểu đồ theo khoảng ngày/gói.
- [ ] Doanh thu chỉ tính thanh toán thành công theo định nghĩa đã chốt.
- [ ] Lối tắt mở giao dịch với bộ lọc tương ứng.
Phụ thuộc: T8. Phạm vi: nhỏ. Kiểm tra: bộ dữ liệu minh họa cho tổng số mua, trạng thái và doanh thu khớp nhau; có empty/error.

## Checkpoint C
- [ ] Các trang Boost và KPI tổng quan dùng cùng định nghĩa dữ liệu.
- [ ] Toàn bộ luồng P0 và Boost có prototype đi hết được.

## T10 — Bài viết
- [ ] ADM-12 có tìm kiếm/lọc và trạng thái nháp/đã đăng/ẩn/lưu trữ.
- [ ] ADM-13 có nội dung, ảnh bìa, chuyên mục, xem trước và lưu nháp/xuất bản.
- [ ] Có lỗi dữ liệu và cảnh báo rời trang khi chưa lưu.
Phụ thuộc: T1. Phạm vi: vừa. Kiểm tra: tạo nháp → xem trước → xuất bản → ẩn; mở lại đúng nội dung.

## T11 — Hỗ trợ người dùng, khi có chatbot handoff
- [ ] ADM-14 có inbox, lịch sử hỗ trợ và trả lời.
- [ ] Trạng thái chưa xử lý/đang xử lý/đã giải quyết được ghi là đề xuất để đối chiếu backend.
- [ ] Có trường hợp gửi lỗi và hội thoại không còn truy cập được.
Phụ thuộc: T1 và chốt phạm vi chatbot. Phạm vi: nhỏ. Kiểm tra: mở yêu cầu → trả lời → giải quyết; lỗi gửi không làm mất bản nháp.

## T12 — Tri thức AI, khi triển khai AI/RAG
- [ ] ADM-15 có trạng thái đồng bộ catalog và lỗi gần nhất.
- [ ] Danh sách tài liệu có tải lên/xóa và trạng thái xử lý.
- [ ] Đồng bộ lại có trạng thái đang chạy và kết quả; xóa tài liệu có xác nhận.
Phụ thuộc: T1 và chốt phạm vi AI/RAG. Phạm vi: nhỏ. Kiểm tra: upload lỗi, indexing lỗi và thử lại; không cho thấy đồng bộ xong khi vẫn đang chạy.

## T13 — Rà soát và bàn giao
- [ ] Đối chiếu toàn bộ frame với use case, cập nhật các phần tài liệu thiếu hoặc mâu thuẫn theo quyết định của nhóm.
- [ ] Kiểm tra desktop/tablet, nội dung dài, focus bàn phím, nhãn, độ tương phản và các trạng thái ngoại lệ.
- [ ] Bàn giao prototype cùng danh sách API/dữ liệu còn thiếu; phân biệt UI minh họa với chức năng đã triển khai.
Phụ thuộc: T1–T10; T11–T12 nếu nằm trong phạm vi triển khai. Phạm vi: vừa. Kiểm tra: chạy thủ công từng prototype và xác nhận mọi nút chính có kết quả thiết kế được mô tả.

## Checkpoint hoàn tất thiết kế
- [ ] Luồng chính và ngoại lệ đã được rà soát.
- [ ] Định nghĩa KPI, trạng thái và chính sách tác động đã thống nhất.
- [ ] Bản thiết kế sẵn sàng để người dùng review và chuyển sang triển khai.
