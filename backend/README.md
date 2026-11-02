# Restore - Second-Hand Marketplace Backend API

Backend API cho dự án **Restore**, nền tảng C2C (Customer-to-Customer) để **mua bán, trao đổi đồ cũ**.

Backend là một REST API viết bằng **Express + TypeScript**, dùng **Prisma ORM** để làm việc với **PostgreSQL trên Supabase**. Code được chia theo module nghiệp vụ, mỗi module tách lớp `route → controller → service → repository`.

> ⚠️ **Trạng thái tài liệu (02/11/2026):** README này mô tả **cấu trúc chuẩn mà backend phải theo**. Các module `auth`, `users`, `home`, `listings/feed`, `listings/favorites` đã theo chuẩn. Các phần còn lại của `listings`, `admin`, `stores`, `promotions` vẫn dồn truy vấn Prisma vào file route. Phần [Lộ trình chuyển đổi](#-lộ-trình-chuyển-đổi-cấu-trúc) liệt kê những gì cần sửa trước khi viết thêm API.

---

## 🚀 Tech Stack

| Công nghệ                     | Mục đích                                                |
| ----------------------------- | ------------------------------------------------------- |
| **Node.js 20+**               | Runtime                                                 |
| **TypeScript**                | Ngôn ngữ lập trình                                      |
| **Express 5**                 | HTTP framework                                          |
| **Supabase**                  | PostgreSQL (cloud và local qua Supabase CLI), Storage   |
| **Prisma ORM**                | Schema, migration, truy vấn database                    |
| **JWT** (access + refresh)    | Xác thực, lưu phiên trong bảng `AuthSession`            |
| **bcrypt**                    | Băm mật khẩu                                            |
| **Resend**                    | Gửi email OTP                                           |
| **Swagger (OpenAPI)**         | Tài liệu API tại `/api-docs`                            |
| **node:test** + `tsx`         | Unit test                                               |
| **GitHub Actions**            | CI                                                      |

> Socket.IO (chat) và lưu ảnh trên Supabase Storage nằm trong kế hoạch, **chưa được cài**. Ảnh hiện lưu ở ổ đĩa server (`uploads/`).

---

## 🧭 Nguyên tắc Supabase + Prisma

Để tránh hai nơi cùng sửa database, dự án chia trách nhiệm như sau:

| Việc                                   | Ai phụ trách                                            |
| -------------------------------------- | ------------------------------------------------------- |
| Định nghĩa bảng, enum, quan hệ         | `prisma/schema.prisma`                                  |
| Tạo và áp dụng migration               | `prisma migrate` (thư mục `prisma/migrations/`)         |
| RLS, policy, function, trigger SQL     | Viết tay trong file `migration.sql` của Prisma migration |
| Chạy Postgres/Storage ở máy local      | Supabase CLI (`supabase/config.toml`)                   |
| Lưu ảnh                                | Supabase Storage (bucket `listing-images`, `content-media`) |
| Truy cập dữ liệu từ app Flutter        | **Chỉ qua Backend API**, app không gọi thẳng Supabase   |

Quy tắc:

- **Không dùng `prisma db push`** trên database dùng chung. Mọi thay đổi schema đi qua `prisma migrate dev` (local) rồi `prisma migrate deploy` (staging/production).
- **Không tạo `supabase/migrations/`.** Prisma là nơi duy nhất giữ lịch sử migration.
- Backend kết nối bằng role `postgres` nên bỏ qua RLS. RLS được bật trên mọi bảng để chặn truy cập trực tiếp qua Supabase Data API bằng khóa `anon`.
- Hai chuỗi kết nối:
  - `DATABASE_URL`: **Transaction pooler** (cổng `6543`, thêm `?pgbouncer=true&connection_limit=1`), dùng khi chạy app.
  - `DIRECT_URL`: **kết nối trực tiếp hoặc Session pooler** (cổng `5432`), Prisma dùng khi chạy migration.
- Chỉ có **một** `PrismaClient` dùng chung, tạo ở `src/lib/prisma.ts`.

---

## 📁 Cấu trúc thư mục chuẩn

```text
Restore/
├── .github/workflows/
│   ├── backend_ci.yml               # CI backend (ở gốc repo, không nằm trong backend/)
│   └── frontend_ci.yml
├── frontend/                        # App Flutter
└── backend/
    ├── prisma/
    │   ├── schema.prisma            # Nguồn duy nhất của schema
    │   ├── migrations/              # Migration do Prisma tạo, kèm SQL RLS viết tay
    │   └── seed.ts                  # Dữ liệu khởi tạo: danh mục, tỉnh/phường, gói cửa hàng, banner mẫu
    │
    ├── supabase/
    │   └── config.toml              # Cấu hình Supabase CLI cho môi trường local
    │
    ├── src/
    │   ├── app.ts                   # Tạo Express app: middleware, gắn router, error handler
    │   ├── server.ts                # Đọc env, gọi app.listen, chạy job nền
    │   ├── routes.ts                # Gắn router của từng module vào /api/v1
    │   │
    │   ├── config/
    │   │   ├── env.ts               # Đọc và kiểm tra biến môi trường
    │   │   └── swagger.ts
    │   │
    │   ├── lib/
    │   │   ├── prisma.ts            # PrismaClient dùng chung
    │   │   └── supabase.ts          # Supabase client (service role) cho Storage
    │   │
    │   ├── middlewares/
    │   │   ├── auth.middleware.ts   # verifyToken, authorizeRoles, requireAuth, optionalAuth
    │   │   ├── validate.middleware.ts
    │   │   ├── request-id.middleware.ts
    │   │   ├── require-json.middleware.ts
    │   │   ├── error.middleware.ts
    │   │   └── logger.middleware.ts
    │   │
    │   ├── common/
    │   │   ├── errors/app-error.ts
    │   │   ├── http/response.ts     # ok(), created(), noContent(), paginated()
    │   │   ├── http/pagination.ts   # Đọc page/limit từ query
    │   │   └── validation/parsers.ts # Hàm kiểm tra đầu vào dùng chung
    │   │
    │   ├── jobs/
    │   │   └── account-status.job.ts # Tự mở khóa tài khoản hết hạn tạm khóa
    │   │
    │   ├── services/
    │   │   ├── email.service.ts
    │   │   └── storage.service.ts   # Upload/xóa ảnh trên Supabase Storage
    │   │
    │   ├── docs/swagger/            # File *.swagger.yaml theo module
    │   │
    │   └── modules/
    │       ├── auth/                # Đăng ký, đăng nhập, OTP, refresh token
    │       ├── users/               # Hồ sơ người dùng, /users/me, khu vực gần đây
    │       ├── home/                # Banner và khu vực mặc định của trang chủ
    │       ├── catalog/             # Danh mục, tỉnh/phường, tình trạng sản phẩm
    │       ├── listings/            # Tin đăng, nháp, ảnh; feed/ (danh sách, gợi ý), favorites/ (lưu tin)
    │       ├── stores/              # Gói cửa hàng, đơn mua gói
    │       ├── promotions/          # Gói đẩy tin, đơn đẩy tin
    │       ├── wanted-alerts/       # Thẻ báo tin khớp nhu cầu
    │       ├── content/             # Bài viết, báo cáo vi phạm, ticket hỗ trợ, tri thức AI
    │       └── admin/               # Kiểm duyệt, quản lý người dùng, thống kê, audit
    │
    ├── scripts/                     # Script vận hành (verify-admin, ...)
    ├── .env.example
    ├── package.json
    └── tsconfig.json
```

### Cấu trúc bên trong một module

Ví dụ với `listings`:

```text
modules/listings/
├── listing.route.ts        # Khai báo endpoint + middleware, KHÔNG chứa logic
├── listing.controller.ts   # Đọc req, gọi service, trả res qua ok()/paginated()
├── listing.service.ts      # Nghiệp vụ: quota, trạng thái, tính isFeatured...
├── listing.repository.ts   # Truy vấn Prisma / $queryRaw, chỉ lớp này import prisma
├── listing.validation.ts   # Kiểm tra body/query, trả về DTO đã làm sạch
├── listing.mapper.ts       # Chuyển bản ghi Prisma sang JSON trả cho app
├── listing.types.ts        # DTO, kiểu dữ liệu của module
└── __tests__/
    └── listing.service.test.ts
```

Luồng xử lý:

```text
Request
  → route        (verifyToken / optionalAuth / authorizeRoles / validate)
  → controller   (lấy tham số, gọi service)
  → service      (nghiệp vụ, transaction)
  → repository   (Prisma)
  → PostgreSQL (Supabase)
```

Quy ước:

- File route chỉ gắn middleware và controller. Không gọi `prisma` trong route hoặc controller.
- Module khác muốn dùng dữ liệu của module này thì gọi **service** của nó, không gọi repository.
- Lỗi nghiệp vụ ném `AppError(status, code, message)`, `error.middleware.ts` chuyển thành JSON.
- Mỗi module có file Swagger riêng trong `src/docs/swagger/`.

---

## 📨 Định dạng phản hồi

Thành công:

```json
{ "success": true, "data": { } }
```

Danh sách có phân trang:

```json
{
  "success": true,
  "data": [ ],
  "pagination": { "page": 1, "limit": 10, "pageSize": 10, "totalItems": 42, "totalPages": 5, "hasMore": true },
  "meta": { "page": 1, "limit": 10, "hasMore": true }
}
```

Lỗi:

```json
{ "success": false, "error": "Tin không còn hiển thị.", "code": "LISTING_NOT_FOUND" }
```

App Flutter đang đọc đúng dạng lỗi này, nên giữ nguyên khi tái cấu trúc.

Tham số phân trang thống nhất là `page` (bắt đầu từ 1) và `limit`.

---

## 🌐 API

Tất cả endpoint nằm dưới tiền tố `/api/v1`. Tài liệu đầy đủ: `http://localhost:3000/api-docs`.

| Tiền tố            | Module          |
| ------------------ | --------------- |
| `/auth`            | auth            |
| `/users`           | users           |
| `/home`            | home            |
| `/catalog`         | catalog         |
| `/listings`        | listings        |
| `/stores`          | stores          |
| `/promotions`      | promotions      |
| `/wanted-alerts`   | wanted-alerts   |
| `/content`         | content         |
| `/admin`           | admin           |

### API trang chủ (Home)

App Flutter (`frontend/lib/modules/home/repositories/home_repository.dart`, lớp `ApiHomeRepository`) gọi các endpoint sau khi tắt mock. Mỗi tin trong danh sách là bản ghi `Listing` kèm các trường đã tính sẵn ở server: `areaLabel`, `distanceKm`, `isFeatured`, `isFavorite`.

Ghi chú chi tiết (header, tham số, kết quả, mã lỗi) nằm ngay trên từng route trong file `*.route.ts`.

| Endpoint | Quyền | Mô tả | File |
| -------- | ----- | ----- | ---- |
| `GET /users/me` | USER, ADMIN | Hồ sơ người đang đăng nhập | `modules/users/users.route.ts` |
| `GET /home/area?provinceCode=&latitude=&longitude=` | Công khai | Tên khu vực, mặc định `Toàn quốc` | `modules/home/home.route.ts` |
| `GET /home/banners` | Công khai | Banner đang chạy `{ id, imageUrl, route }` | `modules/home/home.route.ts` |
| `GET /home/admin/banners` | ADMIN | Toàn bộ banner | `modules/home/home.route.ts` |
| `POST /home/admin/banners` | ADMIN | Tạo banner (ghi AdminAudit) | `modules/home/home.route.ts` |
| `PUT /home/admin/banners/:id` | ADMIN | Sửa banner (ghi AdminAudit) | `modules/home/home.route.ts` |
| `DELETE /home/admin/banners/:id` | ADMIN | Xóa banner (ghi AdminAudit) | `modules/home/home.route.ts` |
| `GET /categories` | Công khai | Danh mục cho thanh danh mục | `modules/catalog/catalog.ts` |
| `GET /listings?filter=newest\|nearby\|exchange&page=1&limit=10` | Công khai, token tùy chọn | Tin mới nhất / gần bạn / trao đổi, có phân trang | `modules/listings/feed/feed.route.ts` |
| `GET /listings/recommended?limit=10` | Công khai, token tùy chọn | Tin gợi ý (đang đẩy nổi bật) | `modules/listings/feed/feed.route.ts` |
| `GET /listings/favorites` | USER | Tin đã lưu, có phân trang | `modules/listings/favorites/favorite.route.ts` |
| `GET /listings/:id/favorite` | USER | Đã lưu tin chưa | `modules/listings/favorites/favorite.route.ts` |
| `POST` (hoặc `PUT`) `/listings/:id/favorite` | USER | Lưu tin | `modules/listings/favorites/favorite.route.ts` |
| `DELETE /listings/:id/favorite` | USER | Bỏ lưu tin | `modules/listings/favorites/favorite.route.ts` |

Header:

| Header | Khi nào |
| ------ | ------- |
| `Authorization: Bearer <accessToken>` | Bắt buộc với API có quyền USER/ADMIN. Với API công khai thì không bắt buộc, nhưng nếu gửi thì token phải hợp lệ (sai hoặc hết hạn trả 401 để app refresh token). |
| `Content-Type: application/json` | Bắt buộc với API nhận body JSON (thiếu trả 415). |
| `Accept: application/json` | Nên gửi. |
| `X-Request-Id` | Tùy chọn. Server luôn trả header này để dò log. |

Middleware dùng chung (`src/middlewares/`):

| Middleware | Việc |
| ---------- | ---- |
| `requestId` | Gắn `X-Request-Id` cho mỗi request |
| `verifyToken`, `authorizeRoles` | Kiểm tra JWT, trạng thái tài khoản, vai trò |
| `requireAuth(...roles)` | Gộp hai middleware trên: `router.get('/x', ...requireAuth(Role.ADMIN), handler)` |
| `optionalAuth` | Cho khách đi qua, có token thì xác thực để biết người xem |
| `requireJson` | Bắt buộc `Content-Type: application/json` |
| `validate({ query, params, body })` | Kiểm tra đầu vào bằng các hàm trong `*.validation.ts`, controller đọc lại bằng `getInput(res)` |
| `notFoundHandler`, `errorHandler` | Trả lỗi theo định dạng chung |

---

## 🛠 Lộ trình chuyển đổi cấu trúc

Làm theo thứ tự, mỗi bước một Pull Request, chạy `npm test` và `npm run build` trước khi merge.

1. ✅ **Khung ứng dụng** (xong app/server/routes, `common/`, `jobs/`): tách `src/index.ts` thành `app.ts`, `server.ts`, `routes.ts`. Chuyển `errors/` vào `common/errors/`, thêm `common/http/response.ts`. Chuyển `lib/account-status.ts` (có trên `main`) thành `jobs/account-status.job.ts`.
2. **Script và database**:
   - ✅ Thêm script `test`, `db:migrate`, `db:deploy`, `db:studio` vào `package.json` (còn `db:seed`).
   - Chuyển `src/modules/catalog/catalog.json` thành dữ liệu seed trong `prisma/seed.ts`, bỏ `scripts/copy-catalog.mjs`.
   - ✅ Bỏ `prisma.config.ts` vì Prisma 5.x không đọc file này (đường dẫn schema/migration và `DATABASE_URL`/`DIRECT_URL` đã khai báo trong `schema.prisma`). Khi nâng lên Prisma 6+ thì thêm lại.
   - Bỏ `docker-compose.yml`, dùng `supabase start` cho database local.
3. **Tách lớp từng module** theo mẫu ở trên: `listings` (file `listing.route.ts` đang dài hơn 500 dòng), `admin`, `stores`, `promotions`. Gộp các route nội dung đang nằm trong `admin/content.route.ts` (có trên `main`, nhánh `fix/product-detail` chưa có) vào module `content`. Đưa `wanted-alert.matcher.ts` vào module `wanted-alerts` và gắn router.
4. ✅ **Module mới cho trang chủ**: `users` (`GET /users/me`), `home` (`GET /home/area`, `GET /home/banners` + bảng `HomeBanner`), chuẩn hóa `GET /listings` và `GET /listings/recommended` theo bảng API trang chủ ở trên.
5. **Ảnh**: chuyển ảnh tin đăng và ảnh nội dung từ ổ đĩa `uploads/` sang Supabase Storage qua `services/storage.service.ts`. Trên Render/Railway, ổ đĩa bị xóa sau mỗi lần deploy nên ảnh hiện tại sẽ mất.
6. **CI**: thêm bước `npm test` vào `.github/workflows/backend_ci.yml` và chạy `prisma migrate diff` để bắt schema lệch với migration.

---

# ⚙️ Cài đặt & chạy

## 1. Yêu cầu

- Node.js v20+
- npm
- [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) (cần Docker) nếu chạy database local

## 2. Cài dependency

```bash
cd backend
npm install
```

## 3. Biến môi trường

Sao chép `.env.example` thành `.env` rồi điền giá trị:

```env
PORT=3000
NODE_ENV="development"

# Supabase Postgres
# Transaction pooler, dùng khi app chạy
DATABASE_URL="postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
# Kết nối trực tiếp hoặc Session pooler, dùng cho migration
DIRECT_URL="postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres"

# Supabase Storage (chỉ dùng ở backend, không đưa vào app)
SUPABASE_URL="https://[PROJECT_REF].supabase.co"
SUPABASE_SERVICE_ROLE_KEY="..."

# JWT (production: mỗi secret tối thiểu 32 ký tự)
JWT_SECRET="..."
JWT_REFRESH_SECRET="..."
JWT_RESET_SECRET="..."
OTP_SECRET="..."

# Email
RESEND_API_KEY="re_..."
EMAIL_FROM="no-reply@your-verified-domain.com"
RESEND_TEST_RECIPIENT="your-resend-account@email.com"   # chỉ cần khi EMAIL_FROM là onboarding@resend.dev

# CORS cho bản web, phân tách bằng dấu phẩy
CORS_ORIGINS="http://localhost:3000"
```

> ⚠️ Không commit file `.env`. Mật khẩu chứa ký tự đặc biệt (`$ % @ #`) phải được URL-encode, VD `$ → %24`, `@ → %40`.

Chạy local bằng Supabase CLI thì dùng:

```env
DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
DIRECT_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
```

## 4. Database

```bash
# Local: bật Supabase (Postgres cổng 54322, Studio cổng 54323)
supabase start

# Tạo Prisma Client
npx prisma generate

# Local: áp dụng migration, tạo migration mới khi sửa schema
npx prisma migrate dev

# Staging / production: chỉ áp dụng migration có sẵn
npx prisma migrate deploy

# Nạp dữ liệu khởi tạo
npx prisma db seed
```

## 5. Chạy server

```bash
npm run dev        # Development, tự reload
npm run build      # Build ra dist/
npm start          # Chạy bản build
npm test           # Unit test
```

Server mặc định chạy tại `http://localhost:3000`, Swagger tại `http://localhost:3000/api-docs`.

---

# 🔄 CI/CD

Workflow `.github/workflows/backend_ci.yml` (ở gốc repo) chạy khi push lên `main`, `dev` hoặc mở PR vào `main`, và chỉ chạy khi thư mục `backend/` thay đổi:

```text
Install → prisma generate → npm test → npm run build
```

---

# 🔒 Bảo mật

- Access token JWT ngắn hạn, refresh token lưu dạng hash trong `AuthSession`, có `authVersion` để thu hồi toàn bộ phiên.
- Mật khẩu và OTP được băm, OTP giới hạn số lần thử và thời gian gửi lại.
- RBAC hai vai trò `USER` / `ADMIN`. Tài khoản `SUSPENDED` / `BANNED` bị chặn ở middleware.
- RLS bật trên mọi bảng public của Supabase. Khóa `service_role` chỉ nằm ở backend.
- Body JSON giới hạn 256 KB, ảnh tối đa 5 MB và được kiểm tra chữ ký file.

---

# 📄 License

Dự án phục vụ mục đích học tập.
