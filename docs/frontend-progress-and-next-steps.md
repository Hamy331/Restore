# ReStore Frontend Progress and Next Steps

> Cập nhật: 2026-09-28  
> Phạm vi: Flutter frontend trong `frontend/`  
> Trạng thái: Foundation, authentication, discovery, chat/offer và selling UI đã được dựng; các luồng nghiệp vụ vẫn chưa được nối backend.

## 1. Source of truth

Mọi feature tiếp theo phải được đối chiếu từ ba nguồn trước khi sửa code:

1. Business requirements: [`RestoreKLTN.md`](./RestoreKLTN.md)
2. Figma: [ReStore UI — v1](https://www.figma.com/design/i9y7pLo1776krlmwDXuWp7/ReStore-UI-%E2%80%94-v1?node-id=85-590&p=f&m=dev)
3. Existing implementation: Flutter app trong `../frontend/`

Quy tắc xử lý xung đột:

- Requirements quyết định hành vi nghiệp vụ.
- Figma quyết định thiết kế, bố cục và các trạng thái giao diện.
- Existing code quyết định convention kỹ thuật khi convention đó vẫn phù hợp.
- Không tự chọn âm thầm khi ba nguồn mâu thuẫn; phải ghi nhận và thống nhất trước khi triển khai phần bị ảnh hưởng.

## 2. Đã hoàn thành

### 2.1 Repository và architecture

- Xác nhận Flutter app đang hoạt động nằm trong `frontend/`.
- Không tạo lại Flutter project và không sửa backend.
- Giữ stack hiện có thay vì thay toàn bộ architecture:
  - BLoC cho state management.
  - `go_router` cho navigation.
  - `dio` cho REST client.
  - `flutter_secure_storage` cho token.
  - `flutter_screenutil` và responsive constraints cho layout.
- Không xóa các Flutter artifact/platform folder ở repository root vì chưa có phê duyệt xác định chúng là obsolete.

### 2.2 Design foundation

Đã tạo hoặc chuẩn hóa:

- Color tokens theo Figma, gồm primary, accent, surfaces, text, borders và error.
- Typography dùng Roboto, type scale từ 12 đến 28 và các weight 400/500/600/700.
- Spacing, radius, control height và responsive content constraints.
- Theme dùng chung tại `frontend/lib/core/theme/theme.dart`.
- Responsive targets:
  - Mobile: 360, 375 và 412 px.
  - Tablet: từ 600 px; nội dung được giới hạn chiều rộng và căn giữa.

Các token chính:

| Token group | Giá trị hiện tại |
|---|---|
| Primary | `#E9A529` |
| Primary dark | `#A65B00` |
| Soft primary | `#FFF1D6` |
| Warm surface | `#FFF9ED` |
| App background | `#FAF9F6` |
| Main text | `#29231B` |
| Secondary text | `#70695F` |
| Border | `#E9E4DB` |
| Error | `#B91C1C` |
| Radius | 4, 8, 10, 12, 16 và pill |
| Main action height | 48 px |
| Auth field height | 49 px |
| Bottom navigation height | 68 px |

### 2.3 Shared components

Đã có foundation component cho:

- Primary/secondary buttons.
- Search field.
- General text field và auth text field.
- Loading, empty và error feedback views.
- Listing card và responsive listing grid.
- Auth screen shell, auth primitives và OTP input.
- Responsive content wrapper.

### 2.4 Authentication UI

Đã triển khai theo Figma page `85:587`:

| Screen | Route | Trạng thái |
|---|---|---|
| Welcome | `/welcome` | Hoàn thành UI |
| Login | `/login` | UI + existing login BLoC/repository |
| Register | `/register` | UI + existing register BLoC/repository; còn conflict `username` |
| Verify email | `/verify-email` | UI preview, chưa có API |
| Email verified | `/email-verified` | UI preview |
| Forgot password | `/forgot-password` | UI preview, chưa có API |
| OTP verification | `/forgot-password/otp` | UI preview, timer/resend chưa hoạt động |
| Reset password | `/reset-password` | UI preview, chưa có reset token lifecycle |
| Reset success | `/password-reset-success` | UI preview |

Đã thêm hai image asset chính xác từ Figma:

- `frontend/assets/images/auth/welcome-camera.png`
- `frontend/assets/images/auth/welcome-lamp.png`

### 2.5 App shell và marketplace preview

- Router và main shell đã có.
- Bottom navigation hiện gồm:
  1. Home
  2. Manage Listings
  3. Create Listing
  4. Messages
  5. Account
- Home, Search và Product Detail đã được cập nhật theo Figma `35:2`.
- Product Detail chỉ dùng `Chat` và `Price Offer`; không có cart hoặc buyer checkout.
- Messages/Conversation, Offer states, Create Listing hai bước, Listing Preview và bốn trạng thái Manage Listings đã được dựng từ Figma `85:584` và `85:585`.
- Offer agreement không tạo order/payment; Mark as Sold chỉ đổi availability của tin.
- Account hiện vẫn là placeholder.
- Listing card/grid hỗ trợ 2 cột trên mobile và 4 cột trên tablet.
- Mobile dùng bottom navigation 5 mục; màn rộng từ 840 px dùng `NavigationRail`.

### 2.6 Environment, storage và startup

- API URL đọc từ `--dart-define=API_BASE_URL`.
- Default Android emulator URL: `http://10.0.2.2:3000/api/v1`.
- Auth token dùng secure storage và có migration fallback từ key cũ `jwt_token`.
- Firebase initialization không còn chặn app startup; app render trước và Firebase init có timeout/failure handling.
- Đã xác nhận Welcome screen render được trên Flutter Web.

### 2.7 Verification đã chạy

- `dart analyze lib test`: không có issue sau batch UI mới.
- Widget tests mới bao phủ Home, Messages, Create Listing và Manage Listings ở 360, 375, 412 và 768 px.
- Lượt test đầu phát hiện overflow Home tại 360 px; lỗi đã được sửa bằng flexible header/section actions.
- Lượt `flutter test` xác nhận lại sau fix chưa chạy được vì quyền ghi Flutter SDK lockfile bị từ chối; cần chạy lại trước khi merge.

Tài liệu liên quan:

- [`frontend-architecture.md`](./frontend-architecture.md)
- [`figma-screen-map.md`](./figma-screen-map.md)

## 3. Còn thiếu

### P0 — Cần xử lý trước khi xem authentication là hoàn chỉnh

| Hạng mục | Hiện trạng | Điều kiện hoàn thành |
|---|---|---|
| Register `username` contract | Figma không có field nhưng backend/requirements cần `username`; frontend đang tạm suy ra từ email | Chọn một contract chính thức và xử lý collision |
| Email verification | Chỉ có UI | Có endpoint gửi mã, verify mã, resend và error mapping |
| Forgot/reset password | Chỉ có UI navigation | Có request OTP, verify OTP, reset token và đổi password thật |
| OTP behavior | Mã, countdown và resend đang tĩnh | Timer, cooldown, retry limit, expired/invalid states hoạt động |
| Google Sign-In | Có nút UI nhưng chưa nối | Firebase/OAuth flow, backend token exchange và error states |
| Session restore | Chưa hoàn chỉnh | App khôi phục session an toàn khi khởi động |
| Refresh token | Chưa hoàn chỉnh | Interceptor refresh một lần, queue request và logout khi refresh thất bại |
| Route guards | Chưa hoàn chỉnh | Public/protected routes điều hướng đúng theo auth state |

### P1 — Marketplace core

- Tạo typed listing models, repository và API data sources.
- Thay fixture ở Home, Search và Product Detail bằng dữ liệu thật.
- Thêm pagination, search debounce, filter và sort.
- Dùng cached network images khi bắt đầu nhận remote image URL.
- Xử lý loading, empty, error, retry và offline cho từng màn hình.
- Nối Create Listing và Manage Listings UI hiện có với repository/BLoC/API.
- Nối upload ảnh Cloudinary, draft, validation và moderation status.

### P2 — Communication và account

- Nối Messages/Conversation UI với Socket.IO, history, unread state và reconnect.
- Persist Price Offer flow và trạng thái thương lượng hiện có.
- FCM notification và deep link.
- Favorites, profile, reviews và report/moderation entry points.

### P3 — Monetization

- Listing boost flow.
- VNPay chỉ được dùng cho paid listing boosts, không dùng cho thanh toán mua sản phẩm.

### Quality còn thiếu

- Localization cho toàn bộ auth copy; một số text hiện đang hard-coded tiếng Việt.
- Golden tests cho visual regression.
- Integration tests cho auth và navigation.
- Accessibility audit đầy đủ: screen reader, focus order, contrast, 200% text scale và tablet landscape.
- Kiểm tra responsive thực tế trên Android/iOS tablet, không chỉ widget constraints.
- Quyết định có giữ `DevicePreview` mặc định trong debug hay bật bằng `--dart-define`.

## 4. Conflicts và quyết định cần chốt

### 4.1 Register username

Conflict:

- Requirements/backend yêu cầu `username`.
- Figma register không có username field.
- Frontend hiện tạm lấy local-part của email làm username.

Rủi ro: trùng username, username không hợp lệ hoặc hành vi không rõ với người dùng.

Các hướng hợp lệ:

1. Backend tự sinh unique username và cho phép đổi sau.
2. Thêm username field vào Figma/register flow.
3. Bỏ username khỏi contract nếu email/user ID đủ làm identity.

Không nên phát triển register production tiếp trước khi chốt một hướng.

### 4.2 Auth UI có trước backend endpoints

Các màn verify email, OTP và reset password hiện được xây như interactive UI preview. Chúng không phải bằng chứng rằng feature đã hoạt động end-to-end. Backend cần thống nhất endpoint, payload, expiry, retry limit và error codes trước khi wiring.

### 4.3 Flutter artifacts ở repository root

Active app là `frontend/`, nhưng repository root vẫn có Flutter/generated residue. Không xóa hoặc gom dọn trong feature work cho đến khi xác nhận ownership và có phê duyệt riêng.

### 4.4 README architecture và product scope

- README mô tả layered architecture với top-level `lib/data/`. Code hiện tại dùng feature-first hybrid: UI/domain nằm trong `modules/`, auth repository nằm trong feature. Batch UI không tạo folder `data/` rỗng; khi nối API sẽ thêm `models/providers/repositories` trong feature tương ứng hoặc refactor có chủ đích.
- Cụm từ “sản phẩm thủy sinh” trong bản README được gửi là sai. ReStore là C2C marketplace đồ cũ tổng quát theo requirements và Figma.
- README gợi ý hard-code base URL trong `api_constants.dart`; implementation hiện dùng `--dart-define` qua `AppEnvironment`, được giữ lại vì an toàn và hỗ trợ nhiều môi trường tốt hơn.

## 5. Có nên làm toàn bộ skeleton UI/UX trước rồi mới implement code không?

Không nên chia thành hai giai đoạn lớn kiểu “dựng toàn bộ app bằng UI giả” rồi “sau đó mới nối toàn bộ logic”. Cách đó dễ làm UI và API contract lệch nhau, sinh nhiều màn placeholder và khiến lỗi nghiệp vụ chỉ lộ ra rất muộn.

Quy trình phù hợp cho ReStore là:

1. **Foundation một lần** — tokens, theme, responsive shell, router, reusable components và common states. Phần lớn bước này đã hoàn thành.
2. **Làm từng vertical slice** — hoàn thiện một luồng từ Figma đến API và test trước khi chuyển sang luồng khác.

Mỗi vertical slice nên đi theo thứ tự:

1. Đọc requirements của feature.
2. Lấy đúng Figma frame, component và các state liên quan.
3. Chốt domain model và API contract.
4. Dựng screen skeleton cùng loading/empty/error/validation states.
5. Nối BLoC, repository, API và secure storage nếu cần.
6. Kiểm tra ở 360, 375, 412 px và tablet.
7. Chạy formatter, analyzer, widget/integration tests và visual QA.

Nói ngắn gọn: **skeleton UI/UX nên được làm theo từng feature rồi nối code ngay trong cùng feature**, không dựng skeleton cho cả ứng dụng trước.

## 6. Thứ tự triển khai đề xuất

### Slice 1 — Complete Authentication

1. Chốt `username` contract.
2. Chốt auth API endpoints và error codes.
3. Implement email verification/OTP/reset password.
4. Implement Google Sign-In.
5. Implement session restore, refresh token và route guards.
6. Thêm auth integration tests và accessibility QA.

### Slice 2 — Listing Discovery

1. Chốt listing DTO/domain model.
2. Nối Home, Search và Product Detail với API.
3. Thêm pagination/filter/sort/cached images.
4. Hoàn thiện all states và responsive QA.

### Slice 3 — Listing Creation and Management

1. Multi-step listing form.
2. Cloudinary upload.
3. Draft/edit/delete/mark-sold flows.
4. Moderation status và rejection feedback.

### Slice 4 — Chat and Price Offer

1. Conversations và message history.
2. Socket.IO realtime/reconnect.
3. Price Offer states.
4. FCM và deep links.

### Slice 5 — Account and Trust

- Profile, favorites, reviews, reports và account settings.

### Slice 6 — Listing Boost

- Boost packages, VNPay payment, return handling và boost status.

## 7. Definition of Done cho mỗi screen

Một screen chỉ được xem là hoàn thành khi:

- Đúng business rules trong requirements.
- Đối chiếu đúng Figma frame và interaction states.
- Không phá convention của code hiện có.
- Có loading, empty, error, validation và retry phù hợp.
- Hoạt động ở 360, 375, 412 px và tablet.
- Không overflow ở text scale lớn.
- Có accessibility labels/focus behavior cần thiết.
- Không chứa hard-coded secret hoặc environment URL production.
- Có widget test; có integration test nếu là critical flow.
- Formatter, analyzer và relevant tests pass.

## 8. Cách chạy frontend hiện tại

Từ repository root:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Nếu chỉ muốn xem UI mà backend chưa chạy, Welcome và các presentation screen vẫn có thể hiển thị; những thao tác cần API sẽ không hoàn thành.

Kiểm tra chất lượng:

```powershell
cd frontend
dart format lib test
flutter analyze
flutter test
```

## 9. Việc nên làm ngay tiếp theo

Không mở rộng thêm screen mới ngay. Bước tiếp theo nên là một buổi contract review ngắn cho Authentication, ưu tiên quyết định `username` và định nghĩa endpoint cho verify email/OTP/reset password. Sau đó hoàn thiện Slice 1 end-to-end trước khi chuyển sang marketplace APIs.
