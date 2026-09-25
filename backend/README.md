# Restore - Second-Hand Marketplace Backend API

Backend API cho dự án **Restore** — nền tảng C2C (Customer-to-Customer) dành cho việc **mua bán, trao đổi các sản phẩm thủy sinh cũ/đã qua sử dụng**.

Hệ thống được xây dựng theo hướng **Modular/Clean Architecture**, cung cấp RESTful API phục vụ quản lý người dùng, bài đăng, thương lượng giá, trao đổi sản phẩm, nhắn tin thời gian thực và kiểm duyệt nội dung.

---

## 🚀 Tech Stack

| Công nghệ          | Mục đích                  |
| ------------------ | ------------------------- |
| **Node.js 20+**    | Runtime Environment       |
| **TypeScript**     | Ngôn ngữ lập trình        |
| **Express.js**     | Backend Framework         |
| **PostgreSQL**     | Cơ sở dữ liệu             |
| **Supabase**       | PostgreSQL Cloud Database |
| **Prisma**         | ORM                       |
| **JWT**            | Authentication            |
| **bcrypt**         | Password Hashing          |
| **Socket.IO**      | Real-time Communication   |
| **Cloudinary**     | Image Storage             |
| **GitHub Actions** | CI/CD                     |

---

## 📁 Project Structure

Backend được tổ chức theo các module độc lập, giúp dễ dàng mở rộng và bảo trì.

```text
backend/
├── .github/
│   └── workflows/
│       └── ...                  # GitHub Actions CI/CD
│
├── prisma/
│   └── schema.prisma            # Prisma Database Schema
│
├── src/
│   ├── middlewares/
│   │   ├── auth.middleware.ts   # JWT Authentication & RBAC
│   │   └── logger.middleware.ts # API Logger
│   │
│   ├── modules/
│   │   ├── auth/                # Authentication & Account Management
│   │   ├── listings/            # Product Listings
│   │   ├── offers/              # Price Negotiation & Exchange
│   │   ├── chat/                # Buyer-Seller Chat
│   │   ├── reports/             # User & Listing Reports
│   │   └── admin/               # Admin Management & Moderation
│   │
│   └── index.ts                 # Application Entry Point
│
├── .env                         # Environment Variables
├── package.json                 # Dependencies & Scripts
├── tsconfig.json                # TypeScript Configuration
└── README.md
```

---

## ✨ Main Features

### 🔐 Authentication & Authorization

- User Registration
- User Login
- JWT Authentication
- Password hashing với bcrypt
- Role-Based Access Control (RBAC)
- User/Admin authorization

### 🛒 Listings

- Create product listings
- Update product listings
- Delete listings
- View product details
- Manage listing status
- Upload product images

### 💰 Offers & Exchange

- Send price offers
- Accept / Reject offers
- Counter offers
- Product exchange
- Manage offer status

### 💬 Real-time Chat

Sử dụng **Socket.IO** để hỗ trợ:

- Buyer ↔ Seller messaging
- Real-time messages
- Real-time notifications
- Conversation management

### 🚨 Reports

Cho phép người dùng báo cáo:

- User violations
- Inappropriate listings
- Other marketplace violations

### 🛡️ Admin

Admin có quyền:

- Review reported content
- Moderate listings
- Ban / unban users
- Manage users
- View system statistics

---

# ⚙️ Installation & Setup

## 1. Requirements

Đảm bảo máy đã cài đặt:

- **Node.js v20+**
- **npm** hoặc **yarn**
- **PostgreSQL**

Dự án sử dụng **Supabase** để lưu trữ PostgreSQL Database.

---

## 2. Clone Repository

```bash
git clone <repository_url>
cd backend
```

---

## 3. Install Dependencies

```bash
npm install
```

---

## 4. Environment Variables

Tạo file `.env` tại thư mục gốc:

```env
PORT=3000

# JWT
JWT_SECRET="supersecretkey"

# PostgreSQL - Supabase
DATABASE_URL="postgresql://postgres:[URL_ENCODED_PASSWORD]@[HOST].supabase.co:5432/postgres"

# Cloudinary
CLOUDINARY_CLOUD_NAME="..."
CLOUDINARY_API_KEY="..."
CLOUDINARY_API_SECRET="..."
```

> ⚠️ **Lưu ý:** Không commit file `.env` lên GitHub.

### PostgreSQL Password

Nếu password PostgreSQL chứa các ký tự đặc biệt như:

```text
$
%
@
#
```

cần **URL-encode** password trước khi đưa vào `DATABASE_URL`.

Ví dụ:

```text
$ → %24
% → %25
```

---

# 🗄️ Database Setup

Sau khi cấu hình `.env`, chạy:

### Generate Prisma Client

```bash
npx prisma generate
```

### Push Database Schema

```bash
npx prisma db push
```

Database lúc này sẽ được đồng bộ theo schema trong:

```text
prisma/schema.prisma
```

---

# ▶️ Running the Server

## Development

Chạy server ở môi trường development với hot reload:

```bash
npm run dev
```

Server mặc định chạy tại:

```text
http://localhost:3000
```

---

## Production

Build project:

```bash
npm run build
```

Start server:

```bash
npm start
```

---

# 🔄 CI/CD

Project sử dụng **GitHub Actions** để tự động kiểm tra code trước khi merge.

CI pipeline thực hiện các bước chính:

```text
Push / Pull Request
        │
        ▼
Install Dependencies
        │
        ▼
Generate Prisma Client
        │
        ▼
TypeScript Build
        │
        ▼
Run Tests
        │
        ▼
      PASS
        │
        ▼
   Ready to Merge
```

Các workflow được đặt tại:

```text
.github/workflows/
```

---

# 🔒 Security

Một số nguyên tắc bảo mật được áp dụng:

- JWT cho authentication
- bcrypt cho password hashing
- RBAC cho User/Admin
- Environment variables cho sensitive credentials
- `.env` không được commit lên repository
- Authentication middleware bảo vệ các API yêu cầu đăng nhập

---

# 🧩 Architecture

Project sử dụng kiến trúc **Modular/Clean Architecture**.

Mỗi module chịu trách nhiệm cho một domain cụ thể:

```text
Request
   │
   ▼
Routes
   │
   ▼
Controller
   │
   ▼
Service
   │
   ▼
Prisma / Database
```

Các domain chính:

```text
Auth
 ├── Register
 ├── Login
 └── Account

Listings
 ├── Create
 ├── Update
 ├── Delete
 └── Search

Offers
 ├── Offer
 ├── Counter Offer
 ├── Accept
 ├── Reject
 └── Exchange

Chat
 ├── Conversation
 ├── Message
 └── Real-time Events

Reports
 ├── User Report
 └── Listing Report

Admin
 ├── Moderation
 ├── User Management
 └── Statistics
```

---

# 🌐 API Overview

Các API được tổ chức theo từng module:

```text
/api/auth
/api/listings
/api/offers
/api/chat
/api/reports
/api/admin
```

> Chi tiết endpoint có thể được bổ sung trong API documentation của project.

---

# 📦 Database

Database sử dụng:

**PostgreSQL + Prisma + Supabase**

Các entity chính bao gồm:

```text
User
Listing
Offer
Chat
Message
Report
...
```

Database schema được định nghĩa tại:

```text
prisma/schema.prisma
```

---

# ☁️ Media Storage

Hình ảnh sản phẩm được lưu trữ thông qua **Cloudinary**.

Flow upload:

```text
Mobile App
    │
    ▼
Backend API
    │
    ▼
Cloudinary
    │
    ▼
Image URL
    │
    ▼
PostgreSQL
```

Database chỉ lưu URL của hình ảnh thay vì lưu trực tiếp file image.

---

# 📜 Available Scripts

Các script chính:

```bash
# Development
npm run dev

# Build
npm run build

# Production
npm start

# Generate Prisma Client
npx prisma generate

# Sync database schema
npx prisma db push
```

---

# 🤝 Development Workflow

Recommended workflow:

```text
Create Branch
     │
     ▼
Develop Feature
     │
     ▼
Run Tests
     │
     ▼
Commit
     │
     ▼
Push
     │
     ▼
Create Pull Request
     │
     ▼
GitHub Actions CI
     │
     ▼
Merge
```

---

# 📄 License

This project is developed for educational and project purposes.
