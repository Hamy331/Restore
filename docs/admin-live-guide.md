# Admin dùng dữ liệu thật

## Chạy dự án

Trong `backend`, cấu hình `.env` như dự án hiện có rồi chạy:

```powershell
npx prisma migrate deploy
npx prisma generate
npm run dev
```

Trong `frontend`:

```powershell
flutter pub get
flutter run -d chrome --dart-define=USE_MOCK_DATA=false
```

Đăng nhập bằng tài khoản đã xác minh, có `role = ADMIN`. Sau đăng nhập mở `/admin`; tài khoản admin cũng có lối vào từ trang Tài khoản. Chỉ người quản trị database được cấp vai trò ban đầu; ứng dụng không có API tự nâng quyền.

`main_admin_preview.dart` và `/admin-preview` vẫn là bản mẫu độc lập, không thay dữ liệu thật. Workspace thật tại `/admin` gọi API bất kể cờ dữ liệu mẫu của các module khác.

## Hành vi

- Kiểm duyệt dùng `updatedAt` để chống quyết định trên dữ liệu cũ. Duyệt cần ảnh và danh mục/tình trạng còn dùng. Yêu cầu chỉnh sửa, từ chối hoặc gỡ tin đưa tin về `REJECTED`, ghi lý do; chủ tin phải sửa và gửi duyệt lại. Không dùng `HIDDEN` cho gỡ tin để tránh chủ tin tự hiện lại.
- Xử lý báo cáo và thay đổi đối tượng nằm trong cùng transaction. Báo cáo xử lý lần hai bị từ chối.
- Cảnh báo, đình chỉ, cấm và khôi phục chỉ áp dụng thành viên đã xác minh; không thay quyền hoặc xử lý tài khoản admin. Đình chỉ/cấm thu hồi phiên và tăng `authVersion`. Đình chỉ hết hạn được giải phóng bằng tác vụ mỗi 60 giây và khi xác thực; user phải đăng nhập lại.
- Ngừng danh mục/tình trạng chặn sử dụng mới và chặn duyệt mới; giữ dữ liệu tin cũ. Bộ thuộc tính category cũ được giữ khi đổi tên/mô tả.
- Đơn chờ xác nhận vẫn yêu cầu đối soát thanh toán ngoài ứng dụng. Xác nhận và nhật ký nằm cùng transaction. Đơn quảng cáo cùng loại được xếp nối tiếp. Không có cổng thanh toán tự động/VNPAY.
- Cấu hình BASIC/PRO thay hạn mức của thuê bao hiện tại; giá áp dụng đơn mua mới. Gói cá nhân vẫn miễn phí, không có ưu tiên/lượt quảng cáo kèm theo. Chu kỳ thuê bao hiện dùng 30 ngày.
- Gói quảng cáo 1–30 ngày. Đẩy Tin có priority 0, Tin Ưu Tiên có priority 1–10. Gói đã có đơn hoặc lượt sử dụng không được thay loại, thời hạn, ưu tiên.
- Bài viết lưu dạng văn bản thuần, có slug, trạng thái, ảnh bìa tải riêng và tối đa 10 ID tin quảng cáo. Blog công khai chỉ trả bài xuất bản và tin liên quan còn hiển thị; bản nháp/ảnh nháp chỉ admin xem được.
- Ticket hỗ trợ, phản hồi và trạng thái được lưu thật. Người dùng chỉ xem/phản hồi ticket của mình; ticket đã đóng không nhận phản hồi mới.
- Banner trang chủ có tên nội bộ, ảnh, đường dẫn, thứ tự, trạng thái bật/tắt và thời gian chạy; mọi thay đổi được ghi vào AdminAudit. Ảnh tải từ admin web được lưu trong kho media hiện có.
- Bài viết bảng tin của người dùng có thể bị báo cáo đúng theo ID bài viết. Admin xem nội dung/ảnh và gỡ bài hoặc bác báo cáo; gỡ bài và ghi audit nằm trong cùng transaction. Bài bị gỡ sẽ xóa bình luận và lượt thích liên quan theo khóa ngoại.
- Tri thức nhận nội dung dán hoặc file UTF-8 TXT/Markdown tối đa 100 KB. Lập chỉ mục là tìm kiếm từ khóa có chuẩn hóa tiếng Việt; chỉnh tài liệu làm chỉ mục hết hiệu lực cho tới lần lập chỉ mục tiếp theo. Đồng bộ catalog lấy dữ liệu thật từ bảng Category. Đây không phải tích hợp LLM/embedding hoặc xử lý PDF; không dùng trạng thái mô phỏng “đã đồng bộ AI”.
- Audit chỉ đọc qua API; ghi actor, thời điểm, đối tượng, hành động và lý do. Các bảng mới bật RLS, thu hồi truy cập trực tiếp từ PUBLIC/anon/authenticated. Kết nối Prisma phía server phải dùng role sở hữu/bypass RLS, không dùng role client Supabase.

## API

Admin: `/api/v1/admin/{me,dashboard,listings,users,reports,catalog,posts,tickets,knowledge,audit,store-packages,store-orders,promotion-orders}`; banner trang chủ được quản lý tại `/api/v1/home/admin/banners`. Mutation được bảo vệ theo quyền admin.

Người dùng/public: `/api/v1/content/{posts,media,knowledge/search,reports,reports/mine,tickets}`. Báo cáo hỗ trợ tin đăng, thành viên và bài viết bảng tin; đọc blog và gửi hỗ trợ từ trang Tài khoản.

## Kiểm chứng local

```powershell
# backend
npm run build
npx tsx --test src/modules/listings/listing.route.test.ts src/modules/promotions/promotion.route.test.ts
# Cài PostgreSQL tạm ngoài repo, không dùng DB thật:
npm install --prefix "$env:TEMP/restore-admin-verification" --no-save @electric-sql/pglite@0.5.8 @electric-sql/pglite-socket@0.2.11
npx tsx scripts/verify-admin.ts "$env:TEMP/restore-admin-verification/node_modules"
# frontend
flutter test --no-pub
```

Migration đã được kiểm thử trên PostgreSQL tạm, không tự triển khai lên Supabase. Ảnh hiện lưu ở `backend/uploads/admin`; khi deploy cần volume bền vững. Các bản xem trước vẫn có test riêng và giữ nguyên dữ liệu mẫu.

Tham khảo thiết lập quyền: [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).
