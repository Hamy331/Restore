# Kế hoạch UI Admin ReStore

Ngày: 2026-09-29. Trạng thái: đề xuất thiết kế, chưa triển khai UI hoặc sửa Figma.

## Căn cứ và phạm vi

- Chat `Document_Restore_Capstone` (01a0e105-742d-7cc2-a555-efceb1e047a2): đã mô tả tổng quan, hàng đợi và chi tiết kiểm duyệt; còn thiếu các luồng quản trị khác. Đây là thông tin từ chat, chưa xác minh lại file Figma hiện tại.
- `docs/RestoreKLTN.md`, mục 4.1.2 và các use case 5.2.17, 5.2.25–5.2.29: căn cứ nghiệp vụ chính cho kế hoạch.
- `docs/figma-screen-map.md`: tái sử dụng bảng màu, typography và spacing của ReStore.
- Mã màn hình ADM bên dưới chỉ phục vụ thiết kế, không thay số use case trong báo cáo.
- Giả định thiết kế: admin ưu tiên desktop, có bố cục tablet. Đây là đề xuất về giao diện, chưa quyết định framework hoặc tạo ứng dụng web riêng.

## Điều hướng và khung giao diện

Sidebar: Tổng quan; Tin đăng; Người dùng; Báo cáo vi phạm; Danh mục & tình trạng; Boost; Bài viết. Thêm Hỗ trợ và Tri thức AI khi triển khai các chức năng tương ứng.

Header: tên trang, breadcrumb ở trang chi tiết, tài khoản admin và đăng xuất. Bộ tìm kiếm và bộ lọc đặt trong từng module. Badge hiển thị số tin chờ duyệt và báo cáo chưa xử lý.

Desktop đề xuất rộng 1440 px, sidebar 240 px, phần nội dung co giãn. Tablet thu sidebar thành thanh icon hoặc drawer. Các con số là kích thước thiết kế đề xuất, không phải yêu cầu đã chốt.

Dùng Roboto; nền #FAF9F6, surface #FFFFFF, chữ #29231B, viền #E9E4DB; màu thương hiệu #E9A529 và #A65B00. Kiểm tra độ tương phản khi dùng màu vàng cho nút/chữ. Trạng thái có cả nhãn và màu.

## Danh sách màn hình

| Mã | Màn hình | Nội dung và thao tác | Căn cứ / mức ưu tiên |
|---|---|---|---|
| ADM-00 | Truy cập admin | Tái sử dụng đăng nhập; phân luồng theo quyền; hết phiên; không có quyền; đăng xuất | Nền tảng |
| ADM-01 | Tổng quan | Tin chờ duyệt, tin đang hiển thị, báo cáo chưa xử lý, người dùng mới, giao dịch hoàn tất, doanh thu Boost; lọc thời gian; biểu đồ xu hướng; việc cần xử lý; hoạt động gần đây | 4.1.2, 5.2.25; P0 |
| ADM-02 | Danh sách tin / hàng đợi | Tab chờ duyệt, đang hiển thị, cần chỉnh sửa, từ chối, bị gỡ; tìm theo mã/tiêu đề/người bán; lọc danh mục/ngày/trạng thái; phân trang | 5.2.26 và 4.1.2; P0 |
| ADM-03 | Chi tiết kiểm duyệt | Ảnh lớn, tiêu đề, giá, mô tả, tình trạng, khu vực, chủ tin, lịch sử; duyệt, yêu cầu sửa, từ chối; gỡ tin đang hiển thị vì vi phạm | 5.2.26 và 4.1.2; P0 |
| ADM-04 | Danh sách người dùng | Avatar, tên, email, vai trò, xác minh, uy tín, trạng thái, ngày tạo; tìm kiếm và lọc | 4.1.2; 5.2.17 cần đồng bộ; P0 |
| ADM-05 | Chi tiết người dùng | Hồ sơ, tin đăng, lịch sử báo cáo đã gửi/bị báo cáo, lịch sử xử lý; cảnh báo, đình chỉ có thời hạn, cấm tài khoản | 4.1.2; P0 |
| ADM-06 | Danh sách báo cáo | Mã báo cáo, loại đối tượng, lý do, người gửi, thời gian, trạng thái; tab báo cáo tin/người dùng; lọc và phân trang | 4.1.2; cần bổ sung use case Handle Reports; P0 |
| ADM-07 | Chi tiết xử lý báo cáo | Nội dung, bằng chứng, đối tượng, lịch sử liên quan; giữ/gỡ tin hoặc cảnh báo/đình chỉ/cấm người dùng; bác báo cáo; ghi kết luận | 4.1.2; P0 |
| ADM-08 | Danh mục & tình trạng | Hai tab Danh mục và Tình trạng sản phẩm; danh sách, thêm, sửa, ngừng sử dụng; form modal | 4.1.2; cần bổ sung use case; P0 |
| ADM-09 | Tổng quan Boost | Số lượt mua, Boost đang chạy/hết hạn/lỗi, doanh thu, biểu đồ theo thời gian và gói; lối tắt đến giao dịch | 5.2.27; P1 |
| ADM-10 | Gói Boost | Tên, giá, thời lượng, ưu tiên hiển thị, trạng thái; thêm/sửa/bật/tắt bằng modal | 5.2.28; P1 |
| ADM-11 | Giao dịch Boost | Mã giao dịch, người mua, tin, gói, số tiền, thời gian, trạng thái thanh toán; drawer chi tiết tham chiếu VNPAY và trạng thái kích hoạt Boost | 4.1.2, 5.2.27–29; P1 |
| ADM-12 | Danh sách bài viết | Tìm kiếm/lọc bài nháp, đã đăng, đang ẩn, lưu trữ; tạo mới, sửa, ẩn, lưu trữ | 4.1.2 Blog / Content Management; P1 |
| ADM-13 | Soạn bài viết | Tiêu đề, nội dung, ảnh bìa, chuyên mục; xem trước, lưu nháp, xuất bản | 4.1.2; P1 |
| ADM-14 | Hỗ trợ người dùng | Inbox các hội thoại chatbot chuyển cho admin; lịch sử, nội dung trả lời, trạng thái xử lý; đề xuất bố cục hai cột | 4.1.2; phụ thuộc triển khai chatbot/handoff |
| ADM-15 | Tri thức AI | Trạng thái đồng bộ catalog, thời gian gần nhất, lỗi; đồng bộ lại; danh sách tài liệu RAG, tải lên/xóa, trạng thái xử lý | 4.1.2; phụ thuộc triển khai AI/RAG |

P0 và P1 chỉ là thứ tự làm. Bài viết và Boost vẫn nằm trong phạm vi tài liệu hiện tại, không bị loại khỏi kế hoạch đầy đủ.

## Cấu trúc chi tiết cần thể hiện trong thiết kế

### Tổng quan

- Dòng đầu là KPI; nhóm công việc cần xử lý đặt trước nhóm thống kê tăng trưởng.
- Bên dưới: biểu đồ tin/người dùng/giao dịch theo khoảng ngày; danh sách tin chờ duyệt và báo cáo mới có nút mở chi tiết.
- KPI chưa có dữ liệu do lỗi phải có trạng thái lỗi, không hiển thị giả là 0. Nhãn chỉ rõ khoảng ngày và định nghĩa chỉ số; người dùng mới khác người dùng hoạt động.
- Doanh thu là phí dịch vụ Boost đã xác nhận thanh toán thành công. Số giao dịch mua bán hoàn tất là thống kê hoạt động nền tảng, không phải doanh thu bán hàng của ReStore.

### Kiểm duyệt và xử lý báo cáo

- Trang chi tiết tin: cột chính xem ảnh/nội dung, cột phụ xem chủ tin và quyết định; thanh hành động rõ ràng.
- Modal yêu cầu sửa/từ chối/gỡ tin: lý do bắt buộc, ghi chú, xác nhận; mô tả kết quả người bán sẽ nhận.
- Trang báo cáo liên kết sang đúng tin/người dùng và quay lại giữ bộ lọc cũ.
- Xử lý báo cáo cần hành động phù hợp loại đối tượng và kết luận. Bác báo cáo không tự khôi phục một tin đã bị gỡ bởi quyết định khác.
- Sau lưu thành công: cập nhật trạng thái, ghi lịch sử và thể hiện kết quả thông báo theo nghiệp vụ. Có trạng thái admin khác đã xử lý trước để tránh ghi đè.

### Người dùng

- Đình chỉ: chọn thời hạn và nhập lý do. Cấm tài khoản: lý do và xác nhận hành động.
- Hiển thị lịch sử gồm người xử lý, thời gian, đối tượng, hành động và lý do. Tích hợp ngay trong trang chi tiết; trang Nhật ký quản trị toàn hệ thống là đề xuất mở rộng sau.
- Không suy ra quyền xem mọi cuộc chat riêng từ quyền admin. Hỗ trợ chỉ hiển thị hội thoại được chuyển cho bộ phận hỗ trợ và bằng chứng trong báo cáo.

### Boost, danh mục và nội dung

- Trạng thái thanh toán và trạng thái chạy Boost hiển thị riêng; cần trường hợp đã thanh toán nhưng chưa kích hoạt được.
- Thay giá/ngừng gói cần giữ thông tin gói đã mua trong lịch sử; quy tắc ảnh hưởng tới Boost đang chạy phải được thống nhất trước triển khai.
- Danh mục/tình trạng đang được dùng ưu tiên ngừng áp dụng cho tin mới; cần chốt cách hiển thị tin cũ thay vì xóa quan hệ dữ liệu.
- Bài viết có xem trước ảnh và nội dung, lỗi ở từng trường và cảnh báo khi rời trang còn thay đổi chưa lưu.

## Trạng thái và thành phần dùng chung

- Bảng: tìm kiếm, lọc, xóa bộ lọc, sắp xếp và phân trang; giữ bộ lọc khi quay lại từ chi tiết.
- Trạng thái: đang tải, có dữ liệu, chưa có dữ liệu, không có kết quả tìm kiếm, lỗi và thử lại, không có quyền, hết phiên, đối tượng không còn tồn tại.
- Form: mặc định, lỗi dữ liệu, đang lưu, thành công, lưu thất bại; không mất nội dung khi lỗi.
- Modal xác nhận và nhập lý do; badge trạng thái; tabs; date range; timeline; toast; xem ảnh lớn.
- Thiết kế focus bàn phím, thứ tự tab, nhãn form, lỗi bằng chữ; không chỉ dựa vào màu.
- Không bổ sung thao tác hàng loạt cho các quyết định kiểm duyệt trong vòng thiết kế đầu.

## Thứ tự thực hiện

1. Đối chiếu use case và trạng thái; dựng shell, thành phần dùng chung, luồng truy cập admin.
2. Thiết kế trọn luồng hàng đợi → chi tiết → quyết định kiểm duyệt.
3. Thiết kế người dùng và báo cáo, dùng lại quyết định xử lý vi phạm.
4. Thiết kế danh mục/tình trạng và hoàn thiện tổng quan với đường dẫn vào các hàng đợi.
5. Thiết kế gói Boost → giao dịch → thống kê.
6. Thiết kế danh sách bài viết → soạn thảo → xuất bản.
7. Thiết kế hỗ trợ và tri thức AI theo mức triển khai chatbot/RAG.
8. Hoàn thiện responsive, trạng thái ngoại lệ và prototype các luồng chính; đối chiếu SRS và bàn giao.

Task và tiêu chí nghiệm thu nằm ở `tasks/todo.md`. Checkpoint sau các nhóm kiểm duyệt, báo cáo, Boost/nội dung và trước bàn giao. Công việc hiện tại dừng ở kế hoạch theo yêu cầu.

## Điểm cần thống nhất trước triển khai phần liên quan

| Điểm chưa thống nhất | Ảnh hưởng | Đề xuất cho UI |
|---|---|---|
| 5.2.17 mô tả sửa/xóa tài khoản, 4.1.2 mô tả cảnh báo/đình chỉ/cấm | Sai quyền và hành động trên hồ sơ | Lấy 4.1.2 làm đề xuất cho bản thiết kế; sửa spec sau khi nhóm chốt |
| 4.1.2 cho phép tiền kiểm hoặc hậu kiểm; 5.2.26 có hàng đợi trước xuất bản | Tab, trạng thái và luồng duyệt | Thiết kế hàng đợi trước xuất bản theo 5.2.26, bổ sung gỡ tin đang hiển thị; chốt cơ chế trước nối backend |
| Figma và Word dùng hệ mã khác nhau | Nhầm màn hình với use case | Map theo tên và mục nghiệp vụ, giữ mã ADM riêng |
| Chính sách mở khóa, phục hồi tin, phí Boost khi tin bị gỡ chưa rõ | Có thể đưa ra hành động không được hỗ trợ | Chưa đưa thành hành động chuẩn; chốt quy tắc trước khi thiết kế bổ sung |
| Chatbot hỗ trợ, AI tìm kiếm và RAG chưa rõ mức hoàn thiện | Menu không có dữ liệu hoặc không có luồng thật | Chỉ triển khai các màn tương ứng với chức năng được chọn |
| Thiết kế admin desktop là giả định | Khác app mobile hiện có | Dựng desktop/tablet trước; xác nhận nền tảng khi chuyển sang thực hiện |

## Đầu ra khi thực hiện thiết kế

- Các frame ADM-00–ADM-15 phù hợp phạm vi đã chốt, cùng modal/drawer và trạng thái cần thiết.
- Prototype: duyệt/từ chối tin; xử lý báo cáo; đình chỉ người dùng; thêm gói Boost; tra giao dịch; xuất bản bài viết.
- Bảng đối chiếu màn hình ↔ use case ↔ hành động ↔ trạng thái; ghi rõ phần phụ thuộc backend.
- Kiểm tra nội dung dài, tên dài, ảnh thiếu, dữ liệu trống/lỗi, thao tác bàn phím và tablet.
