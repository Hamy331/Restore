# Chuyển quản trị ReStore sang web

Dùng chung repo, API Express và database với Flutter. Web React + TypeScript dùng Ant Design và được đóng gói bằng Vite.

## Kế hoạch chuyển đổi

| Mốc | Phạm vi | Điều kiện nghiệm thu |
| --- | --- | --- |
| 1. Nền và thành viên | Đăng nhập, đăng xuất, thời hạn phiên, quyền từ /admin/me, tổng quan, tìm kiếm và phân trang thành viên, cảnh cáo/tạm khóa/cấm/khôi phục, nhật ký | Khách nhận 401, USER nhận 403, ADMIN thấy đúng quyền. Kiểm tra một thao tác với tài khoản thử và đối chiếu nhật ký. |
| 2. Kiểm duyệt | Danh sách tin, quyết định duyệt/từ chối/yêu cầu sửa/gỡ, báo cáo vi phạm và tra cứu đối tượng | Cập nhật với updatedAt; xử lý xung đột khi hai admin cùng thao tác. |
| 3. Danh mục và thương mại | Danh mục, tình trạng, gói cửa hàng, gói đẩy tin, duyệt đơn và đối soát | Đối chiếu giá, hạn mức, trạng thái và lịch sử đơn với API. |
| 4. Nội dung và hỗ trợ | Bài viết, ảnh bìa, gắn tin, ticket và phản hồi, tài liệu tri thức, tải file và lập chỉ mục | Kiểm tra vòng đời nội dung và quyền truy cập dữ liệu riêng. |
| 5. Chuyển hẳn sang web | Triển khai bản tĩnh, đối chiếu các luồng trên môi trường thử, rồi gỡ workspace, preview, route và redirect admin trong Flutter | Web đạt đủ các luồng thực tế; tài khoản thường vẫn vào app di động và sử dụng dịch vụ như trước. |

Web quản trị có 11 mục dùng API Express. Bản hiện tại chạy local để phát triển và thử nghiệm.

## Tổ chức mã nguồn

Danh mục nằm trong `features/catalog/`; gói và đơn trong `features/commerce/`. Bài viết, hỗ trợ và kho tri thức lần lượt nằm trong `features/posts/`, `features/support/` và `features/knowledge/`.

- `src/main.tsx` khởi động React và cấu hình giao diện tiếng Việt.
- `src/app/` ghép các màn vào khung quản trị. `navigation.ts` ánh xạ mục menu với quyền mà API trả về.
- `src/features/` chia theo nghiệp vụ: dashboard, members, audit, listings và reports. Component, kiểu dữ liệu và logic riêng của một màn đặt cạnh nhau. Form quyết định của tin đăng và báo cáo dùng chung trong `features/moderation/`.
- `src/shared/api/` quản lý phiên, gọi API và trạng thái tải. `src/shared/ui/` chứa giao diện dùng lại giữa các nghiệp vụ.

Khi thêm màn hình, đặt code trong thư mục nghiệp vụ tương ứng và khai báo quyền trong `app/navigation.ts`. Backend kiểm tra quyền ở từng endpoint.

## Chạy web quản trị

Khởi động backend ở cổng 3000. Trong admin-web chạy `npm ci` rồi `npm run dev`. Mở http://localhost:5173 và đăng nhập bằng tài khoản quản trị của môi trường thử. Vite chuyển các yêu cầu /api sang backend. Token nằm trong bộ nhớ tab; tải lại trang cần đăng nhập lại.

`npm run build` kiểm tra TypeScript và tạo bản tĩnh `dist/`. Các bộ kiểm thử admin, content và commerce trong `backend/test/api/` dùng `TEST_DATABASE_URL` trỏ vào PostgreSQL thử riêng; chúng tạo lại database thử trước mỗi nhóm.

Nút **Trang mua bán** mở địa chỉ web ReStore đã lưu trong trình duyệt. Có thể đặt địa chỉ mặc định bằng `VITE_MARKETPLACE_URL` trước khi chạy hoặc build admin.
