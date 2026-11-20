# Bàn giao dự án KLTN Restore

Cập nhật ngày 08/11/2026, múi giờ Asia/Saigon.

File này tổng hợp công việc trong cuộc trò chuyện cũ và đối chiếu mã nguồn, trạng thái Git tại thời điểm bàn giao. Mục tiêu là giúp tài khoản hoặc trợ lý mới tiếp tục công việc mà vẫn hiểu các quyết định đã chốt. Kết quả test lịch sử và kế hoạch chưa triển khai được ghi riêng bên dưới.

## 1. Đọc trước khi tiếp tục

- Dự án chính là Restore, nền tảng mua bán và trao đổi đồ đã qua sử dụng, gồm app Flutter và backend Express/TypeScript.
- Thư mục làm việc trên máy hiện tại là `C:\Users\Admin\OneDrive\Documents\GitHub\Restore`. Shell là PowerShell trên Windows.
- Remote chính là <https://github.com/Hamy331/Restore.git>. Nhánh công việc của người dùng là `phat`.
- Lấy cấu trúc module `listings` làm chuẩn khi sửa auth, profile, chat và feed. Phần refactor này đã được merge.
- App mặc định dùng API thật. Người dùng đã yêu cầu bỏ dữ liệu giả khỏi luồng chạy thật. Repository mock còn phục vụ test và một số mã demo, cần kiểm tra từng entry point.
- Người dùng yêu cầu rõ rằng `.claude/` phải ở local và không được push GitHub. Bảo vệ `.env`, khóa dịch vụ và cấu hình riêng của máy khi chọn file commit.
- Database Supabase được nhóm dùng chung. Kiểm tra đúng môi trường và lịch sử migration trước mọi thay đổi dữ liệu.
- Đề nghị triển khai auth/Redis mới chỉ dừng ở plan. Ngưỡng người dùng đã sửa là **sai 10 lần/email trong 15 phút, chặn đăng nhập 10 phút**.
- Cập nhật mới nhất trong phiên 08/11: đã triển khai MVP AI và chuyển vector sang Qdrant Cloud theo yêu cầu; người dùng đã cho phép triển khai trên Supabase này. Đọc **mục 14** trước: mục 13 là trạng thái MVP cũ (SQL vectors/chưa có key), đã được thay thế một phần. Chưa commit/push.

## 2. Trạng thái Git được xác minh ngày bàn giao

Đã chạy `git fetch origin main phat` ngày 08/11/2026.

| Mục | Trạng thái |
| --- | --- |
| Nhánh đang checkout | `phat` |
| HEAD và `origin/phat` | `7961bfd10a7e98c0352d774b641ca0ee2e9f3c63` |
| `origin/main` | `28c4f8550fae106b8b8c39aeaa28ee79ca7232a9` |
| PR đã merge | <https://github.com/Hamy331/Restore/pull/28> |
| Tiêu đề PR sau khi người dùng yêu cầu sửa | `Update auth, profile, chat and feed` |
| Nội dung cây mã `phat` và `origin/main` | Trùng nhau ở thời điểm bàn giao |
| Chênh lịch sử | Main có thêm một merge commit so với phat |
| Nhánh `main` local | Vẫn ở `6b0e806`, cũ hơn remote. Cần phân biệt với `origin/main` |

PR #28 đã gộp toàn bộ commit trên phat chưa có ở main, giữ lịch sử từng commit. Lần push trực tiếp main bị GitHub từ chối vì branch protection. Sau đó đã tạo PR, đợi đủ hai check bắt buộc rồi merge thành công.

Hai check đã đạt cho PR đó là `Build & Verify Node.js` và `Analyze & Build Test APK`. Mô tả PR đã được rút gọn sang tiếng Anh theo yêu cầu. Nội dung dài bằng tiếng Việt trong merge commit đã được tạo trước khi người dùng yêu cầu sửa, nên vẫn còn trong lịch sử commit.

Các commit quan trọng để tra cứu

| Commit | Nội dung |
| --- | --- |
| `be028db` | Schema conversation và message |
| `cffa50f` | Chat thật và online presence |
| `b409d67` | Chỉnh sửa profile và follow APIs |
| `05f1d30` | Feed, listing detail và language settings |
| `4db2202` | Cải thiện feed/profile, public profile và follow lists |
| `7279a90` | Merge main vào phat trong quá trình tích hợp |
| `a205e75` | Ảnh feed/avatar và bổ sung schema còn thiếu |
| `e27610f` | Tổ chức state/repository của profile, feed và chat |
| `f8f80b3` | Dùng API thật và tắt giả lập gói mặc định |
| `5521ad5` | Refactor auth/profile/chat/feed theo listings |
| `7961bfd` | Sửa lỗi API và bộ kiểm tra trước khi merge |
| `28c4f85` | Merge PR #28 vào main |

Các thay đổi local hiện có trước khi tạo file bàn giao

```text
frontend/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
frontend/android/build/reports/problems/problems-report.html
frontend/android/local.properties
frontend/build/.last_build_id
frontend/ios/Runner/GeneratedPluginRegistrant.m
.claude/                          # untracked
```

Một số file generated có thể chỉ thay đổi line ending. Cần xem diff trước khi quyết định. Các file trên đã được để nguyên trong lần merge, chưa đưa vào commit sửa lỗi. File bàn giao này cũng là file mới tạo local ở lượt bàn giao.

Còn năm stash, trong đó `stash@{0}` có tên `On phat: phat: refactor + supabase wip`. Còn worktree cũ detached tại `50ebf8b` ở `C:/Users/Admin/AppData/Local/Temp/claude/60de8d3555f079e7/729160fb-1710-4771-8e94-d24d6b0db830/scratchpad/main-wt`. Đây là các bản dự phòng còn tồn tại. Cần kiểm tra nội dung trước khi dọn. Worktree tạm do trợ lý tạo cho lần merge PR #28 đã được dọn.

## 3. Công nghệ và bản đồ mã nguồn

Backend dùng Node.js, Express 5, TypeScript, Prisma 5, PostgreSQL/Supabase, JWT, bcrypt, Resend, Zod và Swagger. Điểm vào dev là `backend/src/server.ts`, tạo app tại `backend/src/app.ts`, gắn route tại `backend/src/routes.ts`. API dùng tiền tố `/api/v1`, Swagger ở `/api-docs`.

Frontend dùng Flutter/Dart, BLoC/Cubit, Dio, GoRouter, flutter_secure_storage, SharedPreferences và bản dịch Việt/Anh. Có Firebase dependencies, nhưng đăng nhập email/mật khẩu hiện đi qua backend JWT. Nút Google trong auth hiện báo chưa được hỗ trợ.

Cấu trúc backend theo module nhóm

```text
backend/src/modules/<module>/
  index.ts
  <module>.validator.ts / .dto.ts / .type.ts
  routes/
  controllers/
  services/
  repositories/
```

Module đơn giản vẫn có thể dùng mẫu phẳng theo quy ước README. PrismaClient dùng chung ở `backend/src/lib/prisma.ts`. Middleware validation Zod ở `backend/src/middlewares/validate.middleware.ts`, helper schema ở `backend/src/common/validation/schemas.ts`.

Các đường dẫn cần biết

| Phần | Backend | Frontend |
| --- | --- | --- |
| Auth | `backend/src/modules/auth/` | `frontend/lib/modules/auth/` |
| Profile | `backend/src/modules/users/` | `frontend/lib/modules/account/` |
| Chat | `backend/src/modules/chat/` | `frontend/lib/modules/chat/` |
| Feed API/bảng tin thật | `backend/src/modules/feeds/` | `frontend/lib/modules/feeds/` |
| Composer và một số UI feed khác | Dùng API liên quan | `frontend/lib/modules/feed/` |
| Ảnh feed/avatar | `backend/src/modules/media/` | `frontend/lib/services/image_upload_service.dart` |
| Storage | `backend/src/services/storage.service.ts` | `frontend/lib/core/network/media_url.dart` |
| Listing | `backend/src/modules/listings/` | `frontend/lib/modules/listings/` |

Frontend hiện có cả `feed` và `feeds`. Cần tra import, router và caller trước khi gộp hoặc xóa. Profile Flutter nằm trong `account`, backend nằm trong `users`, không mặc định có thư mục `profile` riêng.

Trong Flutter, `View` chịu trách nhiệm provider và bố trí responsive, `MobileView` chứa giao diện điện thoại, widget theo từng màn nằm cùng khu vực màn đó. BLoC/Cubit được nhóm theo chức năng. Người dùng thích giao diện kem/vàng hiện tại và các thay đổi UI có cùng nhận diện.

## 4. Các phần đã làm và đã gộp

### Auth và dữ liệu thật

- Đăng ký, xác minh email OTP, gửi lại OTP, đăng nhập, quên mật khẩu, đổi mật khẩu, refresh và logout qua backend.
- `AuthRepository()` mặc định trả `ApiAuthRepository()`.
- `AppEnvironment.useMockData = false` trong `frontend/lib/core/config/app_environment.dart`.
- Nút giả lập gói tắt mặc định, chỉ bật khi có `--dart-define=DEV_PLAN_SWITCH=true`. Gói mô phỏng ảnh hưởng giao diện, backend tính quyền/quota theo dữ liệu thật.
- `AuthBloc` giữ người dùng đăng nhập cho cả app, `context.currentUser`/`watchUser()` đọc trạng thái này. Trang tài khoản dùng người dùng hiện tại làm thông tin ban đầu rồi tải profile.
- Guard hiện ở `frontend/lib/modules/auth/utils/auth_route_guard.dart`, có `/splash`, `?from=` quay lại trang dự định, kiểm tra đường dẫn nội bộ và chặn admin ở frontend.
- Backend kiểm tra quyền qua middleware và role/database. Guard frontend chỉ là một phần điều hướng.

### Profile

- Xem và sửa hồ sơ, avatar, bio, public profile, follow/unfollow, danh sách followers/following, bài đăng theo tác giả.
- Profile có thông tin đánh giá và presence. Khái niệm public profile trong UI vẫn cần xem quyền API thực tế, vì router users hiện dùng xác thực cho các route liên quan.
- Tab tài khoản có tin của người dùng và bài viết, phân trang và tải lại.

### Chat

- Hội thoại, gửi/đọc tin nhắn, unread count, heartbeat và online presence đã nối API.
- Có endpoint SSE `/api/v1/conversations/events`. Event listeners hiện lưu trong bộ nhớ của một process backend tại `chat/services/chat.events.ts`.
- Socket.IO chưa được cài. Khi mở rộng nhiều instance cần xem lại phân phối event giữa các instance.

### Feed và bình luận

- For you/Following, đăng bài, tải ảnh, xóa bài của mình, thả tim bài/bình luận, report và liên kết profile.
- Bình luận theo yêu cầu người dùng có reply, mở/thu gọn phản hồi và gửi ảnh.
- Giao diện bình luận dùng hàng phẳng kiểu TikTok, tim ở bên phải, giữ nhận diện Restore. Người dùng đã yêu cầu bỏ bubble chat cho bình luận.
- Repository thật ở `frontend/lib/modules/feeds/repositories/feeds_repository.dart`, comments UI ở `frontend/lib/modules/feeds/widgets/feed_comments_sheet.dart`.

### Các phần tích hợp từ main

Listing detail, nháp theo gói, địa chỉ Việt Nam/GPS/gợi ý địa chỉ, wanted alerts, quick actions theo gói, các chức năng admin/content đã có trong lịch sử main. Đây là công việc tích hợp của nhóm, không quy toàn bộ thành phần cho riêng người dùng phat. Tra commit và module để xác định nguồn thay đổi.

## 5. Ảnh, Supabase và migration

Bucket Supabase được dùng theo thiết kế **private**, tên mặc định `media`. Trước đây từng có hướng dẫn bật Public, sau đó đã được sửa lại. App truy cập ảnh thông qua backend.

Các khu vực lưu ảnh

| Loại | Khu vực storage |
| --- | --- |
| Listing | `listings/` |
| Nội dung admin | `admin/` |
| Bài viết và ảnh bình luận | `feeds/` |
| Avatar | `avatars/` |

Upload feed/avatar qua `POST /api/v1/media/images?purpose=feed|avatar`, body là bytes JPEG/PNG/WebP, tối đa 5 MB. Backend trả đường dẫn tương đối `/api/v1/media/<feeds|avatars>/<userId>_<uuid>.<ext>`. Ảnh bài và avatar được backend phục vụ qua GET `/api/v1/media/:area/:name` hiện cho phép truy cập không cần token. Quyền private của bucket và quyền đọc qua API là hai lớp riêng.

Biến môi trường cần cấu hình ở backend

```dotenv
STORAGE_DRIVER=supabase
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<backend-only-secret>
SUPABASE_STORAGE_BUCKET=media
```

Giá trị trên là placeholder. Khóa thật nằm trong môi trường của máy hoặc hosting. Driver mặc định `disk` lưu dưới `backend/uploads/`, cần kiểm tra driver khi đổi máy hoặc deploy.

Các migration quan trọng của quá trình tích hợp

```text
20261005000000_user_chat
20261018000000_profile_presence_follow
20261103000000_feed
20261104000000_store_package_draft_limit
20261104010000_restore_profile_chat_feed_schema
20261105000000_feed_comment_replies_images
```

Migration quota nháp có personal 3, basic 10, pro 30. Migration khôi phục schema bổ sung profile/chat/feed còn thiếu và có kiểm tra tồn tại. Migration cuối bổ sung `FeedComment.imageUrl`, `parentId`, quan hệ reply và index.

Trong phiên cũ đã xử lý tình trạng schema cloud thiếu và lịch sử/checksum của migration khôi phục. Chi tiết trạng thái database hiện tại cần xác minh bằng `npx prisma migrate status`. Lịch sử trong file này không thay thế việc đối chiếu `_prisma_migrations`. Các migration đã triển khai phải được giữ nhất quán giữa nhóm.

Prisma là nguồn quản lý schema/migration. Database dùng chung cập nhật qua `npx prisma migrate deploy`. `prisma db push`, reset database và seed demo đều có thể tác động dữ liệu, cần xác định rõ môi trường trước khi chạy.

Trong phiên cũ đã từng chỉnh cấu hình pool local sang session pool cổng 5432, `connection_limit=5` để khảo sát tốc độ. README và `.env.example` có thể mô tả transaction pool 6543 với `pgbouncer=true`. Cần đọc cấu hình thực tế trên môi trường mục tiêu. Đây chưa phải quyết định deploy chung cho cả nhóm.

## 6. Auth/token hiện tại và plan chưa triển khai

Các file chính

```text
backend/src/modules/auth/services/auth.service.ts
backend/src/modules/auth/services/token.service.ts
backend/src/modules/auth/repositories/auth.repository.ts
backend/src/modules/auth/auth.validator.ts
backend/src/middlewares/auth.middleware.ts
frontend/lib/core/network/api_client.dart
frontend/lib/services/token_storage.dart
frontend/lib/modules/auth/repositories/auth_repository.dart
frontend/lib/modules/auth/bloc/auth/auth_bloc.dart
```

Đã xác minh hiện tại

- Access JWT có hạn 15 phút. Refresh token có hạn 60 ngày, gia hạn và xoay vòng mỗi lần refresh.
- Refresh token lưu hash trong bảng `AuthSession`. `rotateSession` đã dùng transaction với điều kiện phiên cũ chưa bị thu hồi, phát hiện token dùng lại.
- Middleware kiểm tra trạng thái tài khoản, role và `authVersion` trong database. Reset mật khẩu hiện tăng `authVersion` và thu hồi refresh sessions.
- Flutter lưu access/refresh và cached user qua `flutter_secure_storage`. Ghi token lần đầu được thực hiện tuần tự để tránh lỗi khóa mã hóa trên web.
- Interceptor đã có `_refreshFuture` để gom một số request 401. Hàm `refreshSession()` gọi trực tiếp `_refreshTokens()` nên chưa dùng chung toàn bộ entry point.
- Refresh client hiện chưa cấu hình timeout riêng. Nhánh refresh coi mọi lỗi HTTP 4xx là hết phiên, cần đánh giá lại khi thêm 429 rate limit.
- Nếu refresh lỗi mạng, interceptor có thể trả lại 401 gốc của `/auth/me`, khiến `restoreSession()` xóa phiên. Đây là phát hiện qua đọc code, chưa có test hồi quy tái hiện trong lượt review.
- Chưa có cơ chế chống kết quả refresh/restore cũ ghi lại trạng thái sau logout hoặc đổi tài khoản.
- Chưa có Redis trong dependency/backend hiện tại và chưa có limiter đăng nhập theo email/IP.
- OTP hiện có hạn 5 phút, tối đa 5 lần sai, gửi lại chờ 60 giây. Việc kiểm tra và cập nhật còn cần xem xét cạnh tranh giữa request đồng thời.
- Reset JWT hiện có hạn 10 phút, nhưng API reset còn kiểm tra thời hạn OTP 5 phút. Token chưa gắn với một lần cấp OTP cụ thể. Bước kiểm tra điều kiện reset nằm ngoài transaction đổi mật khẩu, nên cần xử lý khả năng hai request cùng vượt qua kiểm tra.
- Zod đã dùng trong auth và nhiều module khác. Auth có schema transform gọi các hàm validation đang giữ error code/field. Feed/chat/profile còn một số validation viết tay.

Plan người dùng đã yêu cầu viết, chưa có thay đổi code cho plan này

| Nội dung | Thông số hoặc hành vi đã đề xuất |
| --- | --- |
| Đăng nhập sai theo email | **10 lần/15 phút, chặn 10 phút** theo chỉnh sửa cuối của người dùng |
| Yêu cầu đăng nhập theo IP | 50 lần/15 phút, mức khởi đầu đề xuất |
| Gửi lại OTP | Cách nhau ít nhất 60 giây |
| Gửi OTP theo email | 5 lần/giờ, mức khởi đầu đề xuất |
| Gửi OTP theo IP | 20 lần/giờ, mức khởi đầu đề xuất |
| OTP | 5 phút, sai tối đa 5 lần/mã |
| Reset token sau cải thiện | 5 phút, dùng một lần, gắn với từng yêu cầu và lưu hash |
| Access/refresh | Duy trì 15 phút/60 ngày cùng cơ chế rotation hiện có |

Thứ tự triển khai đã đề xuất

1. Hoàn thiện refresh ở mọi entry point, timeout, xử lý offline, hủy kết quả cũ sau logout/đổi tài khoản. Cache access token trong RAM và đồng bộ secure storage.
2. Gắn reset token với yêu cầu OTP, cấp mã mới thì vô hiệu mã/token trước. Kiểm tra và sử dụng token, đổi mật khẩu, thu hồi phiên trong cùng transaction. Có thể cần migration mới.
3. Tích hợp Redis dùng chung connection cho rate limit. Cập nhật counter/TTL nguyên tử. Trả 429 với thời gian thử lại, cấu hình IP/proxy theo hosting thực tế.
4. Tận dụng Zod kiểm tra cấu hình JWT, Redis, timeout và giới hạn ngay khi khởi động. Cập nhật `.env.example` và cách chạy Redis local cho nhóm.
5. Test cạnh tranh, mất mạng, giới hạn, reset token cũ và chạy lại bộ kiểm tra phù hợp.

Đề xuất Redis lỗi thì endpoint cần rate limit trả 503 mới là lựa chọn trong plan, chưa được triển khai. Cần quyết định triển khai phù hợp yêu cầu vận hành trước khi thêm dependency này. Redis có thể dùng cache catalog/tình trạng sản phẩm khoảng 5–15 phút, xóa cache khi sửa dữ liệu. Đây là đề xuất tối ưu tiếp theo, chưa có benchmark hay code.

Nguồn đã tham khảo trong cuộc trao đổi

- <https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html>
- <https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html>
- <https://redis.io/docs/latest/develop/programmability/eval-intro/>
- <https://zod.dev/>

## 7. Lỗi cũ đã xử lý và kết quả kiểm tra

Trong lần chuẩn bị merge, commit `7961bfd` đã xử lý

- Sửa endpoint tình trạng sản phẩm từ `/conditions` thành `/catalog/conditions` và thêm test contract ở Flutter.
- Bỏ auth middleware toàn cục trên feed router, thêm `verifyToken` ở từng route. Trước đó URL không tồn tại có thể bị router feed trả 401 thay cho 404.
- Thêm bộ đếm vào ID của `MockListingsRepository` để tránh trùng timestamp trên Windows, sửa các lỗi test quota/xóa nháp liên quan.
- Cho phép truyền repository test vào HomeView, TrustedShopsView và PostComposerView, giữ mặc định dùng API thật.
- Dùng `package_config.json` để tìm font, bỏ phụ thuộc đường dẫn pub-cache và tên user trên máy.
- Thêm 12 ảnh baseline dưới `frontend/test/shots/out/` cho home/shop/composer, đã kiểm tra hình ảnh và chạy test trên Windows.
- Cập nhật snapshots API cho các trường profile và phản hồi catalog. Test teardown dừng server trong `finally` để tránh treo nếu lưu snapshot lỗi.
- Giữ `cacheExtent` tương thích Flutter CI bằng ignore có phạm vi rõ cho cảnh báo deprecation trên SDK local mới hơn.

Kết quả trong phiên ngày 06/11/2026 trên bản mã tương ứng

| Kiểm tra | Kết quả lịch sử |
| --- | --- |
| Backend `npm run build` | Đạt |
| Backend `npm test` | 63/63 |
| Backend `npm run test:api` | 22/22 |
| Flutter `flutter analyze --no-pub` | Không có issue |
| Flutter `flutter test --no-pub --reporter expanded` | 104/104 |
| CI backend trên PR #28 | Đạt |
| CI Flutter analyze và build APK trên PR #28 | Đạt trên Linux |

Những lỗi `account_view_test`, `listing_drafts_test` và screenshot tests được nhắc trước merge thuộc bối cảnh cũ. Bộ Flutter cuối đã đạt 104/104. Nếu lỗi xuất hiện lại, cần dùng log mới để chẩn đoán. CI frontend hiện tắt bước unit tests, backend CI chủ yếu generate Prisma và build TypeScript. Bộ screenshot mới được chạy đầy đủ trên Windows, chưa xác minh chạy screenshot trên Linux.

Lượt tạo file bàn giao chỉ đọc mã nguồn/Git và tạo tài liệu. Các bộ test trên chưa được chạy lại ngày 08/11/2026.

## 8. Các việc còn dở và giới hạn đã biết

- Toàn bộ plan cải thiện auth/token/Redis ở mục 6 chưa triển khai.
- Menu tài khoản chưa nối đầy đủ các màn đã có từ main. `account/views/account/widgets/account_menu.dart` còn dùng `showComingSoon` cho Đã lưu và Trợ giúp. Cần nối Tin nháp (`ListingDraftsView.path`), `/favorites`, `/support`, `/admin` cho admin và `/blog` theo nhu cầu đã trao đổi.
- Log người dùng từng có 404 ở `/search/trending`, `/search/history`, `/search/suggestions`, `/listings/search` và `/users/me/recent-areas`. Frontend vẫn có các caller, backend chưa có đầy đủ handler tương ứng. `/listings/search` có thể rơi vào route `/:id`. Cần xác minh, bổ sung API hoặc chỉnh contract khi làm phần tìm kiếm/khu vực.
- Nút Google login/register vẫn chỉ báo chưa hỗ trợ.
- Một số menu và UI còn placeholder. Yêu cầu dùng data thật nghĩa là không lấp lỗi API bằng dữ liệu giả để khiến giao diện trông như thành công.
- Feed rỗng sau chuyển data thật cần kiểm tra đúng database, API response, bộ lọc và status tác giả. Bài cũ có thể là mock hoặc ở môi trường khác. Trong lịch sử này chưa có bằng chứng kết luận đã xóa bài thật.
- User từng báo các API mất khoảng 1–3 giây. Chưa có benchmark đầy đủ trước/sau. Đo riêng thời gian DB, bcrypt, gửi email, số request nền và vị trí hosting trước khi cam kết mức tăng tốc.
- Event chat hiện lưu trong process, cần thiết kế chia sẻ khi deploy nhiều backend.
- README có chỗ cũ hơn mã, ví dụ mô tả feed router yêu cầu auth trên mọi đường dẫn hoặc schema comment chỉ có text. Đọc implementation và test hiện hành trước khi dựa hoàn toàn vào README.

## 9. Repo web riêng

Trong cuộc trò chuyện có yêu cầu tạo web React + Vite + TypeScript dùng chung backend. Remote là <https://github.com/Ivanzxje/restore-web.git>.

Đã kiểm tra read-only ngày 08/11/2026

- Có thư mục `C:\Users\Admin\OneDrive\Documents\GitHub\restore-web` bên cạnh repo chính.
- Local repo web đang ở nhánh `main`, **chưa có commit nào**. Ref theo dõi `origin/main` báo gone trong metadata local, chưa fetch riêng repo web để khẳng định trạng thái remote mới nhất.
- Có các file untracked như `src/`, `e2e/`, `.env.example`, README, package/lock, Vite/TypeScript/Playwright config.
- package có React, Vite, TypeScript, React Query, Axios, React Hook Form, Zod, Tailwind, Vitest và Playwright.
- Script là `npm run dev`, `npm run build`, `npm test`, `npm run test:e2e`.
- Lượt bàn giao chưa audit nội dung source hay chạy test repo web. Cần đánh giá riêng trước khi kết luận mức hoàn thành hoặc commit/push.

PR #28 thuộc repo Restore chính. Các file web untracked trong repo bên cạnh không nằm trong lần merge đó.

## 10. Chạy dev và kiểm tra

Repo gốc Restore không có `package.json`. Chạy npm từ thư mục gốc đã từng gây lỗi ENOENT.

Backend, mở terminal riêng tại repo Restore

```powershell
Set-Location backend
npm install
npx prisma generate
npm run dev
```

Cần cấu hình môi trường backend trước. Khi cần cập nhật database đã xác định đúng môi trường, kiểm tra `npx prisma migrate status` rồi dùng `npx prisma migrate deploy` cho các migration có sẵn.

Flutter, mở terminal khác tại repo Restore

```powershell
Set-Location frontend
flutter pub get
flutter gen-l10n
flutter run -d chrome
```

API mặc định là `http://localhost:3000/api/v1` cho web và `http://10.0.2.2:3000/api/v1` cho Android emulator. Có thể đặt `--dart-define=API_BASE_URL=https://<backend-host>/api/v1` khi chạy/build môi trường khác. Port backend 3000 là API, frontend Flutter có địa chỉ dev riêng theo output `flutter run`.

Khi đổi field của class const, Flutter có thể từ chối hot reload với `Const class cannot remove fields`. Dùng `R` hot restart. Trong phiên trước hot restart đã chạy thành công, nên log hot reload cũ không tự chứng minh có lỗi code hiện tại.

Kiểm tra backend tại `backend/`

```powershell
npm run build
npm test
```

Kiểm tra frontend tại `frontend/`

```powershell
flutter analyze
flutter test --reporter expanded
```

API integration tests cần `TEST_DATABASE_URL` trỏ đến database test local riêng rồi mới chạy `npm run test:api` trong `backend/`. Harness hiện gọi `prisma migrate reset --force` mỗi file test và xóa dữ liệu database đích. Giữ kiểm tra môi trường này khi chạy test. Phiên cũ dùng PostgreSQL 16 trong Docker tạm ở cổng 55432, dữ liệu test riêng, driver storage `disk`; container đó đã được dừng và xóa sau test. Cần tạo database test mới cho lượt tiếp theo.

CI hiện pin Node.js 20 và Flutter 3.35.4. Giữ tương thích các entry point và phiên bản repo đang dùng khi sửa mã.

## 11. Cách người dùng muốn phối hợp

- Trao đổi bằng tiếng Việt, ngắn, cụ thể, tự nhiên. Người dùng đã yêu cầu mô tả PR ngắn bằng tiếng Anh và tránh văn phong giống AI.
- Khi được giao xử lý thì làm tới kết quả có thể kiểm tra, cập nhật tiến độ có ý nghĩa và báo rõ phần còn thiếu.
- Người dùng hay yêu cầu commit/push thành từng phần. Chọn đúng file, xem staged diff và đặt tên theo công việc thực tế. Xác minh branch và yêu cầu hiện tại trước khi xuất bản thay đổi mới.
- Main có branch protection, cần PR và đủ check. Việc merge PR #28 đã hoàn tất, không phải quyền tự động merge mọi thay đổi về sau.
- Tôn trọng dữ liệu và công việc của nhóm, đặc biệt migration Supabase, stash, worktree và local config.

## 12. Bắt đầu lại trên tài khoản mới

Người dùng có thể đính kèm file này vào cuộc trò chuyện mới, hoặc mở repo trên máy rồi gửi đoạn sau

> Đọc RESTORE_HANDOFF.md trong repo KLTN Restore của tôi, nhất là mục 13 về AI mới triển khai. Kiểm tra lại trạng thái Git và kết quả test, rồi tiếp tục cấu hình/đánh giá Gemini và RAG trên tài liệu thật. Dùng listings làm chuẩn cấu trúc; AI chia assistant và rag, RAG chia theo từng quá trình. Plan auth/token/Redis vẫn còn riêng, ngưỡng đăng nhập đã chốt là sai 10 lần/email trong 15 phút thì chặn 10 phút. Khi cần commit, giữ .claude và thông tin bí mật ở local.

Nếu chuyển sang máy khác, cần mang theo repo, các file local chưa commit cần giữ và cấu hình môi trường bằng kênh riêng phù hợp. File này cung cấp bối cảnh, không chứa mật khẩu, JWT thật hoặc khóa dịch vụ để đăng nhập hệ thống.

## 13. AI assistant — phần mới triển khai ngày 08/11/2026

### Các quyết định của người dùng

- Làm plan, implement và cập nhật file bàn giao này.
- Dùng Gemini cho chat/function calling và Gemini embedding cho RAG.
- Backend AI chia riêng `assistant` và `rag`; RAG phải tách từng quá trình.
- Luồng prompt: system instruction + lịch sử thuộc người dùng + câu hỏi mới + tool definitions; chạy tool ở backend, trả function response lại Gemini rồi lấy câu trả lời cuối.

### Những gì có trong mã nguồn

- `AI_ASSISTANT_PLAN.md`: phạm vi MVP và các bước sau.
- `backend/src/modules/ai/README.md`: cấu hình, API, workflow tài liệu, giới hạn và cách chạy evaluation.
- `ai/assistant/`: routes, controllers, repositories, validators, provider Gemini REST, system prompt, orchestrator và tool registry.
- `ai/rag/services/`: ingestion, chunking, embedding, indexing, retrieval, ranking, context. `rag.service.ts` chỉ export entry point. Có routes/controller riêng để admin lập chỉ mục embedding.
- Gemini defaults: `gemini-3.5-flash` và `gemini-embedding-2`, thay được bằng env. Embedding 768 chiều, không truyền taskType (Embedding 2 không hỗ trợ tham số đó).
- Năm công cụ: `search_listings`, `listing_details`, `my_quota`, `search_knowledge`, `prepare_draft`.
- Tìm tin chỉ trả tin AVAILABLE với chủ đang ACTIVE. Chi tiết cho AI không có địa chỉ đường/số nhà, email, password hay token. Hạn mức lấy từ commerce service của chính user đăng nhập.
- Draft là đề xuất title/description/price. Client hiển thị nguyên nội dung để người dùng xác nhận; server mới lưu DRAFT. Chưa tự chọn danh mục/tình trạng/ảnh, người dùng bổ sung trong Tin nháp.
- `createDraftInTransaction` tách từ service listing để xác nhận AI và kiểm tra quota/lưu draft nằm chung một transaction. Đường tạo nháp cũ cũng dùng hàm này.
- Hội thoại và phản hồi lưu PostgreSQL; ownership, requestId chống gửi trùng, lease chống xử lý đồng thời và giới hạn yêu cầu theo user. Endpoint xác nhận không nhận payload sửa lại; đề xuất hết hạn sau 10 phút. Retry xác nhận trả cùng listingId.
- Rate limit hiện là 20 lượt/10 phút và 100 lượt/ngày UTC, lưu DB để nhiều instance cùng kiểm tra. Đây là hạn mức AI, không phải ngưỡng login đã chốt ở plan auth.
- RAG chỉ lấy KnowledgeDocument active, đã index nội dung, đúng updatedAt và đúng model embedding. Tài liệu sửa/tắt/xóa bị loại ở lần retrieval tiếp theo. Chưa nạp văn bản đề xuất credit thành chính sách chính thức.
- Vector Float[] trong Postgres, cosine + từ khóa tiếng Việt, tối đa 1.000 chunks và 40 chunks/tài liệu. Chưa dùng pgvector hay Redis; cần nâng cấp khi kho lớn. Ngưỡng similarity 0.55 cần hiệu chỉnh bằng dữ liệu thật.
- Flutter đã bỏ các thẻ kết quả demo/mục menu giả lập lỗi trong màn hình AI. Cubit/repository gọi API thật, giữ requestId khi retry, có nguồn, listing cards, xác nhận nháp, lỗi và loading.
- Flutter giữ ngữ cảnh khi ở trong trang; mỗi lần vào trang mới tạo hội thoại mới. Server có GET/DELETE hội thoại nhưng chưa có bộ chọn lịch sử hay job tự xóa theo thời hạn.

### Bật tính năng trên môi trường phát triển

1. Xem kỹ database đích trước khi chạy migration. Migration mới chỉ tạo các bảng AI và quan hệ, không xóa bài viết/tài khoản/tin đăng. Chưa chạy trên Supabase chung trong phiên này.
2. Tại `backend/`, chạy `npx prisma generate`, kiểm tra `npx prisma migrate status`, rồi `npx prisma migrate deploy` trên môi trường đã xác định phù hợp.
3. Đặt `AI_ENABLED=true`, `GEMINI_API_KEY` vào backend/.env; model theo `.env.example`. Không đưa key vào Flutter, chat, Git hoặc handoff.
4. Restart backend. Trước khi cấu hình, API trả `AI_NOT_CONFIGURED`, không có dữ liệu giả thay thế.
5. Admin tạo/duyệt tài liệu ở chức năng knowledge hiện có, index nội dung, rồi gọi POST `/api/v1/ai/rag/documents/:id/index` với token admin. Body `{}`. Sau khi sửa tài liệu hoặc đổi embedding model phải index lại.
6. Mở route Flutter `/ai-assistant`. Thử tìm sản phẩm, câu tiếp nối, quota, chính sách và xác nhận lưu nháp.

### Evaluation và phần cần làm tiếp

- `npm run ai:eval` dùng Gemini thật nhưng công cụ trả fixture test, không đọc/ghi DB thật. Phải đặt `AI_LIVE_EVAL=true` và cấu hình provider trước; có thể phát sinh phí API. Chưa chạy live evaluation trong phiên này.
- Bộ live eval gồm 7 tình huống tiếng Việt: tìm theo giá, câu tiếp nối giữ thương hiệu, hạn mức, nguồn chính sách, soạn nháp, prompt injection và hành động credit chưa hỗ trợ.
- Test tự động xác minh ranh giới quyền, idempotency và dữ liệu; không chứng minh LLM luôn trả lời đúng. Trước rollout cần đo chọn tool/args, retrieval đúng nguồn, trả đúng số liệu, chất lượng tiếng Việt, thời gian và chi phí trên Gemini thật.
- Chưa làm ảnh đầu vào, streaming token, ví credit/thanh toán, Redis, pgvector hay tự dọn lịch sử. Không mô tả những phần này là đã hoàn thành.
- Chưa commit/push thay đổi AI. Khi commit cần chọn các file AI, migration, cấu hình mẫu, test, plan và handoff; loại `.claude/`, `.env`, log test và generated/build/local.properties đang bẩn từ trước.

### Kết quả kiểm tra trong phiên AI

- `npm run build`: đạt (TypeScript backend).
- `npm test`: 72/72 đạt. Lần chạy sandbox đầu có 2 test HTTP localhost báo fetch failed; chạy lại ngoài sandbox đều đạt, không sửa test cũ để che lỗi.
- `npm run test:api`: 31/31 đạt, gồm 9 test AI mới. Chạy toàn bộ migration trên database test Docker riêng `restore_ai_test`, cổng localhost 55433; không đụng Supabase.
- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub --reporter expanded`: 108/108 đạt, gồm 4 test AI mới.
- Kiểm tra `.env` chỉ in boolean xác nhận: Gemini key chưa được cấu hình, AI chưa bật. Không in giá trị bí mật. Chưa có kết quả live evaluation để bàn giao.
- Migration `20261108000000_ai_assistant` đã được kiểm tra qua API tests. `AI_LIVE_EVAL=false` chặn script live eval trước khi gọi provider.
- Sau kiểm thử đã xóa container/volume `restore-ai-test-20261108` và log tạm do phiên này tạo. Không dừng các container khác. Muốn chạy API tests lần sau cần tạo lại database test riêng.

## 14. Cập nhật Qdrant Cloud và triển khai thật — 08/11/2026

Mục này cập nhật các thông tin cũ ở mục 13; không tiếp tục theo cấu hình SQL-vector/pgvector cũ.

### Đã hoàn thành

- Người dùng yêu cầu rõ dùng **Qdrant Cloud**, không dùng Qdrant local. Đã thêm QDRANT_URL, QDRANT_API_KEY, QDRANT_COLLECTION vào .env mẫu và chỗ điền trong .env local. Người dùng đã điền key; không ghi key/endpoint cụ thể vào handoff này.
- Endpoint REST đang dùng HTTPS cổng 6333. Key ban đầu trả 403; sau khi người dùng sửa, quyền truy cập đã hoạt động. Collection `restore_knowledge_dev_v1` đã được tạo, vector 768 chiều/Cosine và các payload indexes cần thiết.
- Adapter `rag/repositories/qdrant.repository.ts` dùng REST, api-key trong header, chặn URL dashboard/URL có credentials/non-Cloud, không fallback sang SQL/local. Validate collection để không ghi nhầm vector dimensions.
- PostgreSQL giữ nguồn/chunk text, point ID, documentVersion và generation. Vector mới chỉ ghi lên Qdrant; cột embedding SQL cũ vẫn giữ để migration không phá dữ liệu, record mới ghi mảng rỗng.
- Index từng document có lease, ghi Qdrant với wait=true rồi mới publish metadata SQL trong transaction. Recheck tài liệu trước khi publish. Tài liệu bị sửa/tắt/xóa không được lấy làm nguồn dù Qdrant còn point cũ.
- Trigger trên AiKnowledgeChunk queue point bị xóa vào AiVectorDeletion, kể cả cascade khi xóa document. Cleanup chỉ xóa outbox sau khi Qdrant xác nhận. Backend chạy job cleanup mỗi 5 phút khi AI_ENABLED=true; có endpoint admin `/ai/rag/cleanup` để chạy ngay và GET `/ai/rag/documents/:id/index` xem trạng thái.
- Lỗi database đúng lúc commit có thể để lại vector không được tham chiếu; retrieval không dùng chúng. Chưa có full orphan-vector reconciliation; cần theo dõi/dọn nếu xảy ra outage kiểu này.
- Người dùng đã xác nhận nguyên văn: **“Triển khai AI trên Supabase này”**. Sau xác nhận đã đọc migration trạng thái, thấy chỉ còn đúng hai migration AI, không có migration lỗi, rồi chạy migrate deploy thành công cho `20261108000000_ai_assistant` và `20261108010000_qdrant_rag`.
- Đã bật `AI_ENABLED=true` trong backend/.env. Backend được khởi động bằng npm run dev, báo đang chạy localhost:3000. Phiên công cụ chạy backend là 36309; nếu tài khoản mới không truy cập được session thì kiểm tra listener port 3000 trước khi chạy thêm tiến trình.

### Kiểm thử và đánh giá thật

- TypeScript build đạt sau thay đổi Qdrant và job cleanup.
- Backend unit tests: 76/76 đạt.
- Toàn bộ API tests: 33/33 đạt trên PostgreSQL local riêng; gồm lease index, version thay đổi, Qdrant write thất bại, retry cleanup/outbox và các tests quyền/idempotency trước đó.
- Flutter không thay đổi trong bước Qdrant; kết quả gần nhất: analyze đạt, 108 tests đạt.
- `AI_LIVE_EVAL=true npm run ai:qdrant:check`: tạo embedding bằng Gemini thật, ghi/tìm vector trên Qdrant Cloud đạt; đã xóa đúng vector kiểm thử.
- `AI_LIVE_EVAL=true npm run ai:rag:eval` với TEST_DATABASE_URL local: pipeline Gemini embedding -> Qdrant -> nguồn SQL hợp lệ đạt; tài liệu inactive bị loại. Đã xóa source local và các vector thử. Script chặn database remote để không tạo fixture trong Supabase.
- `npm run ai:eval`: live Gemini đã qua tìm theo giá, câu tiếp nối giữ thương hiệu/ngân sách, hạn mức tài khoản và truy xuất tài liệu (4/7). Ba ca còn lại (draft cần xác nhận, prompt injection, credit chưa hỗ trợ) bị **AI_PROVIDER_RATE_LIMIT**. Thử lại riêng ba ca với AI_EVAL_INTERVAL_MS=60000 vẫn bị quota chặn; không ghi chúng là đã đạt.
- Script eval có AI_EVAL_CASE_FILTER để chỉ chạy lại những ca chưa hoàn tất. Không lặp lại toàn bộ paid eval nếu không có lý do.
- Request Gemini đơn giản và API liệt kê model hoạt động; chưa xác định chắc quota nào chặn request function-calling. Lệnh chẩn đoán sâu cuối không chạy vì bộ duyệt công cụ tự động hết hạn mức Codex, không phải kết luận thao tác không an toàn.

### Việc còn lại

1. **Nguồn RAG thật:** Supabase hiện không có KnowledgeDocument vừa active vừa indexedText khác null. Chưa nạp đề xuất credit/hạn mức làm chính sách thật. Cần nội dung nghiệp vụ được chủ dự án duyệt, tạo/index qua admin rồi gọi endpoint embedding. Không tự tuyên bố kho đã có chính sách đầy đủ.
2. Chẩn đoán quota Gemini bằng mã quota/retry metadata (không in key), rồi chạy lại đúng ba live eval đang bị chặn. Không tự đổi model hoặc nâng cấp billing.
3. Lịch sử hội thoại server đã lưu nhưng Flutter vẫn tạo hội thoại mới mỗi lần vào trang; chưa có history picker/retention. Streaming token, ảnh đầu vào, Redis và nghiệp vụ credit/payment cũng chưa làm. Đây là các bước mở rộng, không gọi là full implementation đã xong.
4. Rà soát và commit đúng file khi người dùng yêu cầu; vẫn chưa commit/push. Loại .env, .claude/, log và generated/build/local.properties bẩn từ trước.
5. Container PostgreSQL test `restore-qdrant-test-20261108` tại localhost:55433 hiện còn (DB restore_ai_test). Đây là container riêng do phiên này tạo, khác các container của dự án khác. Sau khi không còn cần test có thể xóa đúng container/volume này. Không reset Supabase.
6. Các log tạm ai-live-eval*.log và ai-qdrant-*.log trong backend còn để đối chiếu; không commit chúng. Không coi log là bộ dữ liệu nghiệp vụ.

Hướng dẫn vận hành hiện tại nằm trong `backend/src/modules/ai/README.md`; plan đã cập nhật Qdrant Cloud trong `AI_ASSISTANT_PLAN.md`.

## 15. Đổi model chat theo yêu cầu — 08/11/2026

- Người dùng chọn Gemini 3.5 Flash-Lite. Đã đổi GEMINI_MODEL trong backend/.env, .env.example, fallback của GeminiProvider, README AI và plan thành `gemini-3.5-flash-lite`.
- Giữ `gemini-embedding-2` 768 chiều cho RAG; không cần tạo lại vector Qdrant chỉ vì đổi model chat.
- Backend tsx watch đã tự restart sau thay đổi provider và báo đang chạy localhost:3000 với cấu hình mới.
- TypeScript build và 6 test orchestrator/provider đạt. Live eval model mới ghi ở backend/ai-flash-lite-eval.log; kết quả cuối được bổ sung ngay dưới đây. Không đưa log hoặc .env vào commit.
- Kết quả 4/7 live eval ở mục 14 là của cấu hình model cũ; không cộng gộp thành 7/7 của Flash-Lite.
- Kết quả cuối Flash-Lite: 3/3 live eval đã đạt (soạn draft chờ xác nhận, chống gọi công cụ xóa trái phép qua prompt injection, từ chối thao tác credit chưa hỗ trợ). Không bị quota chặn trong lượt chạy này. Bốn tình huống search/context/quota/knowledge trước đó chưa chạy lại trên Flash-Lite.

## 16. Hybrid search và nạp hướng dẫn ban đầu — 08/11/2026

Người dùng yêu cầu nạp trước tài liệu và sau đó yêu cầu rõ **“thêm hybrid luôn”**. Mục này thay thế trạng thái kho RAG rỗng ở mục 14.

- RAG đã chuyển từ dense search + lexical rerank sang **hai nhánh độc lập dense Gemini và sparse TF-IDF**, gộp RRF trên Qdrant. Không gọi là BM25: sparse dùng log-TF với IDF tự tính bởi Qdrant. Tokenizer chuẩn hóa dấu/case tiếng Việt, giữ số và tách mã lỗi; loại một số stopword. Token ID là hash 32-bit cố định (có rủi ro va chạm nhỏ), IDF là thống kê toàn collection. Tokenizer đổi phải version tên vector và reindex.
- Adapter giữ unnamed dense vector hiện tại, thêm sparse named vector `lexical_v1`. Cloud đang chạy 1.19.2; API PATCH collection không thêm mới sparse vector trên phiên bản này, đã sửa sang PUT `/collections/:collection/vectors/lexical_v1` (Qdrant 1.18+). Không xóa/tạo lại collection, không migration SQL thêm. Indexer xử lý trường hợp hai lượt cùng thêm sparse vector.
- Mỗi prefetch tối đa 200 hits, bộ lọc model trên cả hai nhánh; dense cutoff 0.55, sparse chỉ nhận điểm dương. RRF không dùng cutoff cosine cũ. SQL tiếp tục kiểm tra active/indexed/version/model/collection trước khi trả tối đa 5 excerpts. Truy vấn toàn stopword vẫn chạy dense qua RRF. Tài liệu cũ cần reindex để thêm sparse vector.
- **Chỉ áp dụng hybrid cho RAG**, không thay đổi tìm listing. `search_listings` vẫn gọi listing service, lọc tên/giá/danh mục/trạng thái bằng SQL. Không nói listing đã có vector search.
- Đã tạo `backend/knowledge/bootstrap.json`: 3 hướng dẫn khởi tạo từ code về (1) nháp/gửi duyệt, (2) hạn mức và phạm vi credit, (3) tìm/so sánh sản phẩm. Đã nạp thật lên Supabase đã được phép triển khai; mỗi tài liệu 1 chunk, index Gemini Embedding 2 + Qdrant, cleanup không còn pending.
- IDs: `restore-bootstrap-drafts-v1`, `restore-bootstrap-quota-v1`, `restore-bootstrap-search-v1`. Nội dung có nhãn hướng dẫn khởi tạo theo code; không bịa hạn mức/giá/credit. Chưa thay thế bộ chính sách nghiệp vụ chính thức cần chủ dự án duyệt.
- Script `npm run ai:knowledge:bootstrap` mặc định dry run; thêm `-- --apply --verify` để tạo thiếu/index/kiểm tra top1, hoặc `-- --verify` chỉ kiểm tra retrieval. Script không ghi đè nguồn đã sửa hoặc bật lại nguồn đã tắt. Ghi audit actor `system:restore-ai-bootstrap`, kèm file nguồn. Chạy lại với apply có thể reindex tài liệu giống hệt, phát sinh gọi embedding. Không dùng seed demo cho việc này.
- Live Qdrant smoke đạt: hybrid roundtrip, cố ý đảo dấu dense vector để cosine=-1 vẫn được nhánh sparse tìm lại, truy vấn từ khóa lạ không trả kết quả. Điểm thử đã xóa. Live RAG + SQL test local đạt và loại inactive; fixture/vector test đã xóa. Không dùng Supabase cho test reset.
- Cả 3 câu hỏi trên nguồn bootstrap trả đúng tài liệu ở vị trí đầu. Đây là smoke test nhỏ, chưa chứng minh chất lượng trên tập tài liệu lớn. Cần benchmark câu có/không đáp án, mã lỗi/tên gói, truy vấn không dấu, paraphrase, Recall@k/MRR và chất lượng nguồn trích dẫn trước rollout rộng.
- API AI tests 11/11 đạt trên PostgreSQL test local cổng 55433. Kết quả TypeScript/unit cuối được ghi bên dưới. Frontend không đổi trong bước này.
- Các log mới `backend/ai-hybrid-unit.log`, `backend/ai-hybrid-api.log` không được commit. Chưa commit/push, tiếp tục loại `.env`, `.claude/` và generated/build/local.properties.

Các ưu tiên sau bước này: bổ sung chính sách thật; cải thiện recall/precision theo bộ đánh giá; lưu/chọn lịch sử hội thoại trên Flutter; streaming. Credit/payment vẫn chưa triển khai. Bốn live eval chat còn lại trên Flash-Lite vẫn chưa chạy lại.

Kết quả cuối bước hybrid: `npm run build` đạt; **80/80 unit tests** đạt; **11/11 API AI tests** đạt. Unit tests lần đầu trong sandbox có hai HTTP localhost tests bị chặn, chạy lại ngoài sandbox đạt; không sửa test để bỏ lỗi. `ai:knowledge:bootstrap -- --verify` xác nhận **3/3 top1** đạt trên nguồn thật. Backend session 36309 đã tự restart sau thay đổi cuối và báo đang chạy port 3000. Flutter không thay đổi nên không chạy lại analyze/tests trong bước hybrid này.

## 17. Đang triển khai hybrid listing và streaming — 08/11/2026

Người dùng sửa phạm vi: hybrid phải dùng cho listing, đồng thời muốn streaming/trạng thái công cụ và hỏi guardrail/đánh giá. Người dùng yêu cầu tiếp tục, ghi handoff khi gần hết quota, code dễ đọc và không hardcode nghiệp vụ.

**Trạng thái tạm thời, chưa coi hoàn tất:**

- Đã thêm code `assistant/services/listing-search.service.ts` và `assistant/repositories/listing-vector.repository.ts`: collection listing riêng, index Gemini dense+sparse, hybrid tìm kiếm với kiểm tra lại visibility/giá/brand/category và hash nguồn từ SQL. Job index đã viết nhưng CHƯA nối server ở thời điểm ghi mục này.
- Đã thêm Prisma model AiListingIndex và migration `20261108020000_ai_listing_search`: trigger vô hiệu index khi nội dung listing thay đổi; trigger queue xóa vector khi index bị xóa/thay. **CHƯA áp migration này lên Supabase.** Cần kiểm thử trên DB local trước. Cần script sync listing và cập nhật env mẫu/docs.
- Thêm endpoint POST `/ai/assistant/conversations/:id/messages/stream`, SSE status/reset/delta/done/error, Gemini streamGenerateContent, hủy khi client ngắt. Chỉ trả draft/cards sau khi lưu kết quả thành công; JSON endpoint cũ vẫn còn.
- Flutter repository/cubit/view đang nối stream, trạng thái công cụ và partial text; có Fetch adapter riêng cho SSE web vì XMLHttpRequest có thể buffer cả response. Giữ Dio auth/refresh interceptors. Thêm dependency trực tiếp `web` đã có trong cache. Cần kiểm tra analyze, test và build web.
- Backend cũ session36309 đã được dừng bằng Ctrl+C để Prisma generate không bị khóa DLL. Generate sau đó thành công; TypeScript build tại thời điểm này đạt. **Backend hiện cần chạy lại sau migration/test**, không báo người dùng đang chạy khi chưa kiểm tra.
- Lệnh Flutter pub get offline/format/analyze đang chạy ở session11659. Cần xem kết quả trước khi tiếp tục. Chưa có kết quả test cho các thay đổi listing/streaming mới. Các số 80unit/11API ở mục16 là trước thay đổi này.
- Cần bổ sung tests hybrid listing (giá/hãng/hidden/banned/nguồn đổi/xóa), stream UTF-8 phân mảnh/tool signatures/ngắt stream/retry; sửa API test đang gọi search_listings mặc định để dùng index fixture hoặc browse không query; không để test truy cập Qdrant/Supabase thật.
- Backend code mới đang cần rà cấu trúc service/repository và các hằng cấu hình theo yêu cầu người dùng; không hardcode dữ liệu nghiệp vụ. Không commit/push. Không đưa .env/.claude/log/generated vào Git.

### Cập nhật sau khi tiếp tục triển khai (thay thế trạng thái tạm ở trên)

- Đã tách `listing-index.repository.ts` (SQL), `listing-vector.repository.ts` (Cloud adapter), `listing-source.service.ts` (text/hash/brand), `listing-index.service.ts` (pipeline đồng bộ), `listing-search.service.ts` (truy xuất) và `listing-ai-index.job.ts`. Không gọi embedding lại cho tin không đổi; tăng viewCount không làm mất index. `ai.config.ts` chứa SEARCH_LIMITS và cấu hình batch/interval đọc env có validation.
- `search_listings` giờ dùng hybrid thật trên collection **`restore_knowledge_dev_v1_listings`**; RAG giữ collection riêng cũ. Hãng được truyền riêng trong tool schema, kiểm tra theo attributes.brand hiện tại; chỉ fallback tên tin nếu thiếu thuộc tính brand. Price/category lọc ở Qdrant lẫn SQL. Không trả total giả từ top5. Query rỗng là browse có bộ lọc và không gọi embedding.
- Migration `20261108020000_ai_listing_search` đã test trên DB local, kiểm tra Supabase chỉ còn đúng migration này pending, rồi **migrate deploy thành công** theo quyền triển khai AI đã được cấp. Đã index **37 tin công khai**, lượt cuối scanned=0. Không chỉnh nội dung listing/tài khoản, không seed demo vào Supabase.
- Job đã nối `server.ts`; default mỗi 60 giây xử lý tối đa 10 tin. Cấu hình `AI_LISTING_INDEX_BATCH_SIZE`, `AI_LISTING_INDEX_INTERVAL_MS`, `QDRANT_LISTING_COLLECTION` có trong .env.example; collection listing mặc định suy ra từ collection RAG + `_listings`. Sau khi tạo/sửa tin có độ trễ index đến batch thành công tiếp theo; stale hit bị loại ngay qua SQL. Khi quota Gemini lỗi job log mã lỗi rồi thử lần sau, không trả dữ liệu giả. CLI `npm run ai:listings:index -- --all` có thể drain lần đầu.
- Gemini streaming native SSE đã chạy thật, có status và delta. Flutter có trạng thái tiếng Việt/Anh qua l10n, partial text chỉ tạm thời, failure xóa partial, retry giữ request ID; draft/cards chỉ nhận sau done. Giữ endpoint JSON cũ. Fetch adapter chỉ bọc stream route trên web, giữ nguyên Dio auth/refresh; native dùng Dio bình thường.
- Xác minh: TypeScript build đạt; **82/82 backend unit tests**; **2/2 API tests listing** và **12/12 API tests AI** trên DB test local. Test listing cố ý bỏ qua Cloud filters ở double để chứng minh SQL vẫn chặn sai giá/hãng/category, hidden/banned, nguồn đổi/xóa, write fail và không reindex do tăng view. SSE HTTP replay giữ ownership, không gọi model/tăng quota; provider tests kiểm tra chữ ký và UTF-8 chia gói, loại thought, chặn truncated output.
- `flutter analyze --no-pub`: sạch lỗi; **6/6 Flutter tests AI/stream** đạt (partial/progress/failure/retry và parser nhận UTF-8 chia từng byte trước done). Dependency `web` từ transitive thành direct (cùng version đã cache) và thêm l10n keys; không nâng các package khác.
- Live `AI_LIVE_EVAL=true npm run ai:listings:check` đạt: hybrid tìm đúng tin thật với giá/category hiện tại; Gemini thật gọi search_listings và phát 4 text chunks. Script chỉ đọc catalog công khai, không ghi chat/nháp/quota người dùng. Đây là smoke test, không phải benchmark chất lượng trên mọi câu hỏi tự nhiên.
- Backend đã khởi động lại thành công ở localhost:3000, session mới **81387**. Session36309 đã dừng và không dùng nữa. PostgreSQL test container vẫn còn, giữ riêng với Supabase.
- Flutter web debug build đang chạy session **35539**; cần lấy kết quả trước khi kết luận phần kiểm chứng web hoàn tất. Kết quả build được bổ sung tiếp phía dưới. Không cần chạy lại tests đã đạt trừ khi sửa thêm code.
- Guardrails hiện có: auth/owner/role, allowlist+Zod strict tool args, server-side quyền/filters, xác nhận draft trong transaction, hạn mức request/tool/time/output, nguồn SQL hiện hành, prompt chống injection, không có tool credit/payment/publish/admin tùy ý. **Không tuyên bố prompt injection/ảo giác đã được loại tuyệt đối**; cần tập đánh giá đối kháng và kiểm tra câu trả lời dựa trên nguồn.
- Đo độ chính xác nghĩa là bộ câu hỏi có expected filters/IDs/sources/actions: ví dụ chỉ Samsung <=5 triệu phải đúng hãng/giá; câu tiếp nối giữ constraint; tin hidden không được lọt; không có bằng chứng thì không bịa. Tiếp theo cần tập đánh giá đủ lớn, recall@k/MRR và tỷ lệ tuân thủ bộ lọc/tool, latency/token cost. Test/smoke hiện tại chưa là benchmark đó.
- Chưa commit/push. Logs mới `ai-listing-stream-*.log`, .env/.claude và generated/build/local.properties vẫn không được đưa vào commit. Localization generated files có thay đổi hợp lệ từ gen-l10n, phân biệt với build artifacts.

## 18. Lịch sử hội thoại và bộ câu hỏi đánh giá — 08/11/2026

- GET /api/v1/ai/assistant/conversations trả tối đa 30 hội thoại gần đây của tài khoản có ít nhất một lượt hoàn tất. Flutter dùng nút lịch sử để chọn hội thoại, tải 10 lượt gần nhất và gửi tiếp vào đúng ID. Bắt đầu lại giữ cuộc trò chuyện trước đó trên server. Khi tải lịch sử, trạng thái đã lưu nháp lấy từ kết quả xác nhận, đề xuất hết hạn chưa lưu không còn nút xác nhận.
- TypeScript build đạt. 12/12 API AI tests trên restore_ai_test local cổng 55433 và 7/7 Flutter AI/stream tests đạt, gồm kiểm tra cách ly danh sách theo tài khoản và tiếp tục hội thoại cũ.
- npm run ai:rag:benchmark in bộ 15 câu có nhãn cho 3 tài liệu bootstrap, gồm câu không dấu và 3 câu ngoài phạm vi. Thêm -- --live để đo Recall@3, MRR@3 và tỷ lệ truy vấn ngoài phạm vi trả danh sách rỗng. Đã kiểm tra chế độ preview. Chưa có điểm benchmark live.
- Hai ca tìm Samsung trong ai:eval kiểm tra tham số brand và maxPrice. Bốn ca chat Flash-Lite còn lại chưa chạy được vì bước duyệt tự động chặn việc gửi prompt fixture tới Gemini và tiêu quota. Không gộp kết quả của hai model. Thay đổi còn local, chưa commit.
- Flutter web debug (JavaScript) build thành công. Analyze module AI và file test lịch sử đạt. Wasm dry run báo flutter_secure_storage_web còn dùng dart:html.
