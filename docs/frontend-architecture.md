# Flutter frontend architecture

Flutter app hoạt động nằm tại `frontend/`. Thư mục Flutter ở repository root là phần dư chưa được Git theo dõi và không được dùng làm source chính.

## Quy ước

- Giữ BLoC cho state management và dependency boundary hiện có.
- Giữ GoRouter; dùng `StatefulShellRoute.indexedStack` cho năm destination: Home, Manage Listings, Create Listing, Messages, Account.
- UI không gọi HTTP trực tiếp. `ApiClient` chịu trách nhiệm Dio/interceptor; repository là boundary của feature.
- Token do `TokenStorage` quản lý bằng `flutter_secure_storage`, có đọc fallback key cũ để không đăng xuất người dùng đang tồn tại.
- Base URL lấy từ `--dart-define=API_BASE_URL=...`; mặc định chỉ dành cho Android emulator local.
- Assets Figma đã tải vào `frontend/assets/images/marketplace/`. Dữ liệu hiển thị hiện nằm ở `presentation/fixtures`, không phải repository giả.

## Cấu trúc chính

```text
lib/
  core/
    config/       environment values
    constants/    design tokens
    network/      Dio client
    routes/       GoRouter graph
    theme/        Material theme
    ui/           responsive primitives
  modules/
    auth/          BLoC, repository, views
    chat/          messages, conversation and offer presentation
    home/          discovery presentation
    listings/      domain entity, fixtures and listing presentation
    shell/         persistent main navigation
  services/        secure token storage and platform services
  shared/widgets/ reusable UI components and states
```

Đây là cấu trúc feature-first dạng hybrid, phù hợp với các layer trong README nhưng không sao chép nguyên cây thư mục mẫu. Hiện chưa có `lib/data/` cấp cao nhất. Khi kết nối API thật, mỗi feature sẽ bổ sung `data/models`, `data/providers` và `data/repositories` tại nơi cần dùng; không tạo layer rỗng hoặc di chuyển code đang hoạt động chỉ để khớp cây mẫu.

## Error và trạng thái

- BLoC phát loading/success/failure; view hiển thị loading trong CTA và snackbar có semantic màu.
- `FeedbackView` là primitive cho empty/error/not-implemented states.
- API error hiện tiếp tục được repository chuẩn hóa; bước kế tiếp nên thêm typed `AppException` và map status code tập trung.
- Các màn hình marketplace hiện dùng fixture cục bộ và thông báo rõ khi thao tác chưa kết nối API; không giả lập thành công nghiệp vụ.

## Responsive và accessibility

- Nội dung được giới hạn chiều rộng nhưng co giãn theo viewport; listing dùng hai cột ở mobile và bốn cột từ tablet đủ rộng.
- Mục tiêu kiểm thử: 360, 375, 412, 768 và 1024 px.
- Authentication giữ layout full-width trên mobile; từ 600 px dùng card 520 px căn giữa để trường nhập không bị kéo giãn và vẫn giữ hierarchy của Figma.
- Các action dùng widget Material có semantics/touch target; text cho phép scale theo cấu hình hệ điều hành.

## Kiểm thử đề xuất

- Unit: repository/error mapping/token migration khi có mock secure storage.
- Widget: design component states và screen không overflow ở 360/375/412.
- Navigation: route auth, chuyển tab shell, mở search, product detail, conversation và create/preview listing.
- Golden: Welcome, Home, Search, Product Detail, Messages và Create Listing tại ba width sau khi chốt baseline với thiết kế.

## Tích hợp còn lại

Thay `figma_preview_listings.dart` và dữ liệu chat/listing cục bộ bằng repository thật; bổ sung API search/filter/detail, route guards dựa trên auth state, refresh token, OTP/recovery, chat Socket.IO, FCM deep links và upload Cloudinary. VNPay chỉ được phép xuất hiện trong flow boost tin đăng.
