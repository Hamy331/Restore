# Restore - Second-Hand Marketplace Backend API

Backend API cho dự án **Restore**, nền tảng C2C (Customer-to-Customer) để **mua bán, trao đổi đồ cũ**.

Backend là một REST API viết bằng **Express + TypeScript**, dùng **Prisma ORM** để làm việc với **PostgreSQL trên Supabase**. Code được chia theo module nghiệp vụ, mỗi module tách lớp `route → controller → service → repository`.

> ⚠️ **Trạng thái tài liệu (02/11/2026):** README này mô tả **cấu trúc chuẩn mà backend phải theo**. Các module `auth`, `users`, `home`, `listings`, `commerce`, `content`, `admin` đã theo chuẩn. `catalog` (phần công khai) và `wanted-alerts` còn theo kiểu cũ (xem lộ trình). Phần [Lộ trình chuyển đổi](#-lộ-trình-chuyển-đổi-cấu-trúc) liệt kê những gì cần sửa trước khi viết thêm API.

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
    │   │   ├── auth.middleware.ts   # requirePermission, optionalAuth, verifyToken
    │   │   ├── validate.middleware.ts # validate({ query, params, body }) bằng schema zod
    │   │   ├── request-id.middleware.ts
    │   │   ├── require-json.middleware.ts
    │   │   ├── error.middleware.ts
    │   │   └── logger.middleware.ts
    │   │
    │   ├── common/
    │   │   ├── audit/admin-audit.ts # audit(tx, ...): ghi một dòng AdminAudit trong transaction
    │   │   ├── auth/permissions.ts  # PERMISSION + bảng vai trò → quyền
    │   │   ├── errors/app-error.ts
    │   │   ├── http/response.ts     # ok(), created(), noContent(), paginated()
    │   │   └── validation/
    │   │       ├── schemas.ts       # Schema zod dùng lại: pageQuery, coordinates, idParam, str, int...
    │   │       └── admin-input.ts   # Kiểm tra kiểu cũ của API quản trị: text, object, choice, version, changed, page...
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
    │   └── modules/                 # (P) = mẫu phẳng, (N) = mẫu nhóm
    │       ├── auth/            (P) # Đăng ký, đăng nhập, OTP, refresh token
    │       ├── users/           (P) # Hồ sơ người dùng, /users/me
    │       ├── home/            (P) # Banner và khu vực của trang chủ
    │       ├── catalog/         (P) # Danh mục, tỉnh/phường, tình trạng sản phẩm
    │       ├── wanted-alerts/   (P) # Thẻ báo tin khớp nhu cầu
    │       ├── listings/        (N) # Tin đăng, nháp, ảnh, feed, lưu tin, duyệt tin
    │       ├── commerce/        (N) # Gói cửa hàng, gói đẩy tin, đơn mua (gộp stores + promotions)
    │       ├── content/         (N) # Bài viết, báo cáo vi phạm, ticket hỗ trợ, tri thức AI
    │       └── admin/           (N) # /admin: hồ sơ admin, dashboard, thành viên, nhật ký; gắn router quản trị của các module khác
    │
    ├── scripts/                     # Script vận hành (verify-admin, ...)
    ├── .env.example
    ├── package.json
    └── tsconfig.json
```

### Quy ước module

Có hai mẫu. Dùng **mẫu phẳng** khi module chỉ có một thực thể chính; chuyển sang **mẫu nhóm** khi có từ 2 thực thể con trở lên, mỗi thực thể có route riêng. Tín hiệu nên chuyển: một file vượt khoảng 250 dòng, hoặc bắt đầu có thực thể thứ hai.

**Mẫu phẳng** (ví dụ `home`): mỗi lớp một file ở gốc module.

```text
modules/home/
├── index.ts               # export homeRouter và hàm service module khác được dùng
├── home.route.ts
├── home.controller.ts
├── home.service.ts
├── home.repository.ts
├── home.validator.ts      # schema zod
├── home.dto.ts            # kiểu vào (z.output) + kiểu ra + toXxxDto()
├── home.type.ts           # hằng số, kiểu nội bộ
└── home.test.ts
```

**Mẫu nhóm** (ví dụ `listings`): mỗi lớp một thư mục, mỗi thực thể con một file; validator, dto, type vẫn mỗi loại một file chung ở gốc.

```text
modules/listings/
├── index.ts
├── listing.validator.ts
├── listing.dto.ts
├── listing.type.ts
├── routes/          listing.route.ts, draft.route.ts, image.route.ts, feed.route.ts, favorite.route.ts, moderation.route.ts
├── controllers/     listing.controller.ts, draft.controller.ts, ...
├── services/        listing.service.ts, draft.service.ts, ...
└── repositories/    listing.repository.ts, favorite.repository.ts, ...
```

Mỗi file một việc:

| File | Chứa gì | Không được chứa |
| ---- | ------- | --------------- |
| `index.ts` | Export router và các hàm service module khác được dùng | Logic |
| `*.route.ts` | Khai báo endpoint + middleware + ghi chú ngắn | Kiểm tra dữ liệu, truy vấn |
| `*.controller.ts` | Đọc `getInput(res)`, gọi service, trả `ok()` / `created()` / `paginated()` | Nghiệp vụ, `prisma` |
| `*.service.ts` | Nghiệp vụ, transaction, ném `AppError` | `req`, `res` |
| `*.repository.ts` | Truy vấn Prisma / `$queryRaw` | Quy tắc nghiệp vụ |
| `*.validator.ts` | Schema zod cho query, params, body | |
| `*.dto.ts` | Kiểu vào suy ra từ schema, kiểu ra và hàm map `toXxxDto()` | |
| `*.type.ts` | Hằng số, hàng SQL thô, enum riêng module | Kiểu trả ra API |

Quy tắc:

- Chỉ repository được import `prisma`.
- Module khác dùng dữ liệu của module này qua `index.ts` (service), không import repository hay file lẻ.
- Không dùng `*.module.ts` (Express không có cơ chế inject như NestJS, `index.ts` đã làm việc này).
- Không cần `asyncWrapper` hay `try/catch` trong controller: Express 5 tự chuyển lỗi async sang `errorHandler`.
- Lỗi nghiệp vụ ném `AppError(status, code, message, field?)`.
- Phân quyền theo **permission**, không kiểm tra vai trò trực tiếp. Thêm hoặc đổi quyền chỉ sửa `common/auth/permissions.ts` (và bảng mong đợi trong `permissions.test.ts`).

Luồng xử lý:

```text
Request
  → route        (requirePermission / optionalAuth, requireJson, validate)
  → controller   (getInput, gọi service)
  → service      (nghiệp vụ, transaction)
  → repository   (Prisma)
  → PostgreSQL (Supabase)
```

Mẫu route và ghi chú. Ghi chú chỉ mô tả và tham số; quyền và header đọc được từ middleware, mã lỗi chung nằm trong README này.

```ts
/**
 * Sửa banner, chỉ cập nhật trường được gửi, ghi AdminAudit
 *
 * Path params:
 *  - id: string - mã banner
 *
 * Body: như khi tạo, mọi trường đều không bắt buộc
 */
homeRouter.put(
  '/admin/banners/:id',
  requirePermission(PERMISSION.BANNER_MANAGE),
  requireJson,
  validate({ params: bannerIdParams, body: bannerBody(true) }),
  homeController.adminUpdateBanner,
);
```

Validator dùng schema dùng chung trong `common/validation/schemas.ts`; lỗi zod được đổi thành `AppError` 400 với đúng `code` và `field`:

```ts
export const favoritesQuery = pageQuery({ defaultLimit: 20, maxLimit: 100 });  // → { page, limit, skip }
export const listingIdParams = idParam(64);                                      // → { id }
```

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

Lỗi đầu vào có thêm `field` (tên trường sai). Mã lỗi chung:

| Status | code | Khi nào |
| ------ | ---- | ------- |
| 400 | `INVALID_INPUT` (hoặc mã riêng như `INVALID_LOCATION`) | Query, params, body sai |
| 422 | `INVALID_EMAIL`, `WEAK_PASSWORD`, `PASSWORD_REQUIRED`, `INVALID_USERNAME`, `INVALID_FULL_NAME`, `INVALID_OTP_FORMAT`, `TOKEN_REQUIRED` | Body của `/auth/*` sai (mỗi mã ứng với một trường) |
| 401 | `AUTH_REQUIRED` | Thiếu `Authorization` |
| 401 | `INVALID_ACCESS_TOKEN` | Token sai hoặc hết hạn, app refresh rồi gọi lại |
| 401 | `SESSION_REVOKED` | Token cũ sau khi đổi mật khẩu / đăng xuất mọi nơi |
| 401 | `ACCOUNT_UNAVAILABLE` | Tài khoản bị khóa hoặc không còn |
| 403 | `FORBIDDEN` | Vai trò không có quyền cần thiết |
| 404 | `*_NOT_FOUND` | Không tìm thấy |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | API nhận JSON nhưng thiếu `Content-Type: application/json` |

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
| `/stores`          | commerce        |
| `/promotions`      | commerce        |
| `/wanted-alerts`   | wanted-alerts   |
| `/content`         | content         |
| `/admin`           | admin           |

### API trang chủ (Home)

App Flutter (`frontend/lib/modules/home/repositories/home_repository.dart`, lớp `ApiHomeRepository`) gọi các endpoint sau khi tắt mock. Mỗi tin trong danh sách là bản ghi `Listing` kèm các trường đã tính sẵn ở server: `areaLabel`, `distanceKm`, `isFeatured`, `isFavorite`.

Ghi chú chi tiết (header, tham số, kết quả, mã lỗi) nằm ngay trên từng route trong file `*.route.ts`.

| Endpoint | Quyền (permission) | Mô tả | File |
| -------- | ------------------ | ----- | ---- |
| `GET /users/me` | `PROFILE_READ` | Hồ sơ người đang đăng nhập | `modules/users/users.route.ts` |
| `GET /home/area?provinceCode=&latitude=&longitude=` | Công khai | Tên khu vực, mặc định `Toàn quốc` | `modules/home/home.route.ts` |
| `GET /home/banners` | Công khai | Banner đang chạy `{ id, imageUrl, route }` | `modules/home/home.route.ts` |
| `GET /home/admin/banners` | `BANNER_MANAGE` | Toàn bộ banner | `modules/home/home.route.ts` |
| `POST /home/admin/banners` | `BANNER_MANAGE` | Tạo banner (ghi AdminAudit) | `modules/home/home.route.ts` |
| `PUT /home/admin/banners/:id` | `BANNER_MANAGE` | Sửa banner (ghi AdminAudit) | `modules/home/home.route.ts` |
| `DELETE /home/admin/banners/:id` | `BANNER_MANAGE` | Xóa banner (ghi AdminAudit) | `modules/home/home.route.ts` |
| `GET /categories` | Công khai | Danh mục cho thanh danh mục | `modules/catalog/catalog.ts` |
| `GET /listings?filter=newest\|nearby\|exchange&page=1&limit=10` | Công khai, token tùy chọn | Tin mới nhất / gần bạn / trao đổi, có phân trang | `modules/listings/routes/feed.route.ts` |
| `GET /listings/recommended?limit=10` | Công khai, token tùy chọn | Tin gợi ý (đang đẩy nổi bật) | `modules/listings/routes/feed.route.ts` |
| `GET /listings/favorites` | USER (`FAVORITE_READ`) | Tin đã lưu, có phân trang | `modules/listings/routes/favorite.route.ts` |
| `GET /listings/:id/favorite` | USER (`FAVORITE_READ`) | Đã lưu tin chưa | `modules/listings/routes/favorite.route.ts` |
| `POST` (hoặc `PUT`) `/listings/:id/favorite` | USER (`FAVORITE_WRITE`) | Lưu tin | `modules/listings/routes/favorite.route.ts` |
| `DELETE /listings/:id/favorite` | USER (`FAVORITE_WRITE`) | Bỏ lưu tin | `modules/listings/routes/favorite.route.ts` |

Header:

| Header | Khi nào |
| ------ | ------- |
| `Authorization: Bearer <accessToken>` | Bắt buộc với API cần permission. Với API công khai thì không bắt buộc, nhưng nếu gửi thì token phải hợp lệ (sai hoặc hết hạn trả 401 để app refresh token). |
| `Content-Type: application/json` | Bắt buộc với API nhận body JSON (thiếu trả 415). |
| `Accept: application/json` | Nên gửi. |
| `X-Request-Id` | Tùy chọn. Server luôn trả header này để dò log. |

Middleware dùng chung (`src/middlewares/`):

| Middleware | Việc |
| ---------- | ---- |
| `requestId` | Gắn `X-Request-Id` cho mỗi request |
| `requirePermission(...perms)` | Kiểm tra JWT, trạng thái tài khoản và quyền: `router.get('/x', requirePermission(PERMISSION.BANNER_MANAGE), handler)` |
| `authorizePermission(...perms)` | Chỉ kiểm tra quyền, dùng sau khi router cha đã xác thực token (ví dụ router quản trị dưới `/admin`) |
| `verifyToken` | Chỉ xác thực JWT và trạng thái tài khoản; route dùng `requirePermission`, không gọi trực tiếp |
| `optionalAuth` | Cho khách đi qua, có token thì xác thực để biết người xem |
| `requireJson` | Bắt buộc `Content-Type: application/json` |
| `validate({ query, params, body })` | Kiểm tra đầu vào bằng schema zod trong `*.validator.ts`, controller đọc lại bằng `getInput(res)` |
| `notFoundHandler`, `errorHandler` | Trả lỗi theo định dạng chung |

---

### API quản trị (/admin)

`modules/admin/index.ts` gắn `adminRouter` tại `/admin`: mọi đường dẫn bên dưới cần token và quyền `ADMIN_ACCESS` trước (khách 401, thành viên 403, kể cả đường dẫn không tồn tại). Mỗi module có dữ liệu tự cung cấp router quản trị của mình qua `index.ts`, route kiểm tra thêm quyền riêng bằng `authorizePermission`.

Danh sách trả `{ items, total, page }`, 25 dòng mỗi trang. Thao tác ghi kèm `updatedAt` lúc đọc (409 `ADMIN_STALE` nếu dữ liệu đã đổi) và ghi `AdminAudit`. Lỗi đầu vào giữ mã `INVALID_ADMIN_INPUT`, `INVALID_QUERY` như trước.

| Endpoint | Quyền | Module / file |
| -------- | ----- | ------------- |
| `GET /admin/me`, `GET /admin/dashboard`, `GET /admin/audit` | `ADMIN_ACCESS` | `admin/routes/{user,dashboard,audit}.route.ts` |
| `GET /admin/users`, `POST /admin/users/:id/action` | `USER_MANAGE` | `admin/routes/user.route.ts` (logic khóa tài khoản: `users.service.sanctionUser`) |
| `GET /admin/listings`, `POST /admin/listings/:id/decision` | `LISTING_MODERATE` | `listings/routes/admin-listing.route.ts` (logic duyệt: `moderation.service.moderate`) |
| `/admin/posts`, `/admin/tickets`, `/admin/knowledge` | `CONTENT_MANAGE` | `content/routes/admin-content.route.ts` |
| `/admin/reports` | `USER_MANAGE` | `content/routes/admin-content.route.ts` |
| `GET /admin/catalog`, `/admin/categories`, `/admin/conditions/:condition` | `CATALOG_MANAGE` | `catalog/catalog-admin.route.ts` |
| `/admin/store-packages`, `GET /admin/store-orders` | `STORE_ORDER_MANAGE` | `commerce/routes/commerce-admin.route.ts` |
| `GET /admin/promotion-orders` | `PROMOTION_MANAGE` | `commerce/routes/commerce-admin.route.ts` |

---

## 🛠 Lộ trình refactor

Làm từng commit nhỏ, không đổi URL và định dạng JSON. Trước và sau mỗi commit, `npm test` và `npm run test:api` phải xanh; snapshot JSON lệch thì dừng lại sửa code, không sửa snapshot cho khớp.

| # | Phạm vi | Trạng thái |
| - | ------- | ---------- |
| C0–C4 | Nền chung: contract test, zod, `schemas.ts`, `validate` dùng zod, permissions + `requirePermission` | ✅ |
| C5–C6 | `users`, `home` sang mẫu phẳng | ✅ |
| C7 | README quy ước module | ✅ |
| C8–C15 | `listings` sang mẫu nhóm: feed, favorites, tin, nháp, ảnh, duyệt tin, bỏ `listing.route.ts` | ✅ |
| C16–C18 | `commerce`: gộp `stores` + `promotions`, logic duyệt đơn vào service | ✅ |
| C19–C21 | `content` tách khỏi `admin`; endpoint `/admin/*` về module sở hữu dữ liệu; `admin` sang mẫu nhóm, bỏ `admin.route.ts` | ✅ |
| C22 | `auth` sang mẫu phẳng, đầu vào bằng zod (`auth.validator.ts`, giữ lỗi 422 theo trường); bỏ `parsers.ts`, `pagination.ts`, `authorizeRoles`, `requireAuth` | ✅ |
| C23 | `catalog`: dữ liệu vào `prisma/seed.ts`, mẫu phẳng | |
| C24–C25 | Ảnh lên Supabase Storage, chuyển ảnh cũ | |
| C26 | `wanted-alerts`: gắn router, bỏ code chết | |

Còn lại ngoài lộ trình: bỏ `docker-compose.yml` (dùng `supabase start`), thêm `npm test` và `prisma migrate diff` vào `.github/workflows/backend_ci.yml`.

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
npm run test:api   # Contract test: gọi thật mọi API trên database thử, so với snapshot JSON
```

Contract test cần một Postgres thử (Supabase local hoặc Postgres bất kỳ). Test sẽ **reset** database này, và từ chối host không phải local trừ khi đặt `TEST_DB_ALLOW_REMOTE=1`:

```bash
TEST_DATABASE_URL="postgresql://postgres:postgres@localhost:54322/postgres" npm run test:api
UPDATE_SNAPSHOTS=1 TEST_DATABASE_URL=... npm run test:api   # chỉ khi cố ý đổi API
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
