# Restore - Second-Hand Marketplace (Frontend Mobile App)

Đây là mã nguồn ứng dụng di động (Frontend) của dự án **Restore** — nền tảng C2C chuyên mua bán, thương lượng và trao đổi các sản phẩm thủy sinh đã qua sử dụng.

Ứng dụng được xây dựng bằng **Flutter**, áp dụng kiến trúc phân lớp rõ ràng nhằm tách biệt giao diện (UI), quản lý trạng thái (State), dữ liệu (Data) và các dịch vụ ngoại vi (Services).

---

## 🚀 Công nghệ & Thư viện cốt lõi

- **Framework:** Flutter
- **State Management:** BLoC / Cubit
- **Networking:** Dio
- **Local Storage:** Secure Storage / Shared Preferences
- **Routing:** GoRouter
- **Authentication:** JWT Authentication thông qua Backend Node.js
- **Localization:** Đa ngôn ngữ Anh / Việt
- **CI/CD:** GitHub Actions
- **Backend:** Node.js + Express.js + PostgreSQL

---

## 📁 Cấu trúc thư mục dự án

Kiến trúc dự án được tổ chức nhằm đảm bảo khả năng mở rộng, tái sử dụng và dễ bảo trì.

```text
frontend/
├── android/                      # Native Android
├── ios/                          # Native iOS
├── assets/                       # Images, fonts, icons
│
├── lib/                          # Main Flutter source code
│   │
│   ├── core/                     # Core components
│   │   ├── blocs/                # Global BLoC / Cubit
│   │   ├── constants/            # Colors, Images, API Constants
│   │   ├── network/              # Dio, API Client, Interceptors
│   │   ├── routes/               # GoRouter configuration
│   │   ├── theme/                # Theme, Typography, Light/Dark mode
│   │   ├── ui/                   # Responsive UI configuration
│   │   └── utils/                # Helper functions & validators
│   │
│   ├── data/                     # Data layer
│   │   ├── models/               # Data models
│   │   ├── providers/            # API calls
│   │   └── repositories/         # Data repositories
│   │
│   ├── l10n/                     # Localization
│   │   ├── app_en.arb            # English translations
│   │   ├── app_vi.arb            # Vietnamese translations
│   │   └── app_localizations...  # Generated localization files
│   │
│   ├── modules/                  # Feature / UI modules
│   │   ├── auth/                 # Login, Register, Forgot Password
│   │   ├── home/                 # Home & Dashboard
│   │   └── widgets/              # Module-specific widgets
│   │
│   ├── services/                 # External services
│   │   ├── auth_service.dart     # JWT authentication
│   │   └── local_storage_service.dart
│   │
│   ├── shared/                   # Shared UI components
│   │   └── widgets/              # Buttons, TextFields, Dialogs, etc.
│   │
│   └── main.dart                 # Application entry point
│
├── pubspec.yaml                  # Dependencies & assets configuration
└── l10n.yaml                     # Localization generation configuration
```

---

# 🏗️ Architecture

Ứng dụng sử dụng kiến trúc phân lớp:

```text
┌───────────────────────────────┐
│            Modules            │
│       UI / Screens / BLoC     │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│         Repositories          │
│      Business Data Layer      │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│           Providers           │
│        Dio / REST API         │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│       Restore Backend API     │
│    Node.js + Express + JWT    │
└───────────────────────────────┘
```

---

# 🔐 Authentication

Restore sử dụng **JWT Authentication** thông qua Backend API.

Flow đăng nhập:

```text
Flutter App
     │
     ▼
POST /auth/login
     │
     ▼
Backend API
     │
     ▼
Validate Credentials
     │
     ▼
JWT Token
     │
     ▼
Secure Local Storage
     │
     ▼
Dio Interceptor
     │
     ▼
Authorization: Bearer <token>
```

Token được lưu trữ cục bộ và tự động gắn vào các request API thông qua **Dio Interceptor**.

---

# ⚙️ Installation & Setup

## 1. Requirements

Cài đặt các công cụ sau:

- **Flutter SDK:** `>= 3.10.0`
- **Dart SDK:** Phiên bản tương thích với Flutter
- **VS Code** hoặc **Android Studio**
- Android Emulator / iOS Simulator hoặc thiết bị thật

Kiểm tra môi trường:

```bash
flutter doctor
```

---

## 2. Clone Repository

```bash
git clone <repository_url>
cd restore/frontend
```

---

## 3. Install Dependencies

Cài đặt các package được khai báo trong `pubspec.yaml`:

```bash
flutter pub get
```

---

## 4. Generate Localization

Restore hỗ trợ:

- 🇻🇳 Vietnamese
- 🇬🇧 English

Generate localization files:

```bash
flutter gen-l10n
```

Các file ngôn ngữ nằm trong:

```text
lib/l10n/
├── app_en.arb
└── app_vi.arb
```

---

# 🌐 Backend API Configuration

Frontend giao tiếp với Backend thông qua REST API.

Cấu hình Base URL tại:

```text
lib/core/constants/api_constants.dart
```

### Android Emulator

Nếu Backend chạy trên máy local:

```text
http://10.0.2.2:3000/api/v1
```

### Physical Device

Nếu chạy trên thiết bị thật, sử dụng IPv4 của máy tính:

```text
http://192.168.1.X:3000/api/v1
```

Ví dụ:

```text
http://192.168.1.100:3000/api/v1
```

> Thiết bị và máy tính chạy Backend phải nằm trong cùng mạng LAN.

---

# 🔗 Backend Connection

Frontend Restore kết nối tới Backend:

```text
Flutter
   │
   │ HTTP / REST API
   ▼
Node.js + Express
   │
   ▼
Prisma
   │
   ▼
PostgreSQL
```

Backend chịu trách nhiệm xử lý:

- Authentication
- Users
- Listings
- Offers
- Exchange
- Chat
- Reports
- Admin
- Notifications

---

# 🚀 Running the Application

## Development

Chạy ứng dụng ở chế độ Debug:

```bash
flutter run
```

Hoặc chỉ định thiết bị:

```bash
flutter devices
```

```bash
flutter run -d <device_id>
```

---

# 📦 Build APK

Build Android APK ở chế độ Release:

```bash
flutter build apk --release
```

APK sau khi build sẽ nằm tại:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

# 🧪 Testing

Chạy toàn bộ test:

```bash
flutter test
```

Kiểm tra static analysis:

```bash
flutter analyze
```

---

# 🔄 CI/CD

Project sử dụng **GitHub Actions** để tự động kiểm tra source code.

Pipeline cơ bản:

```text
Push / Pull Request
        │
        ▼
Install Flutter
        │
        ▼
flutter pub get
        │
        ▼
flutter analyze
        │
        ▼
flutter test
        │
        ▼
flutter build apk
        │
        ▼
      PASS
```

Workflow được lưu tại:

```text
.github/workflows/
```

---

# 🌍 Localization

Ứng dụng hỗ trợ hai ngôn ngữ:

| Language   | File         |
| ---------- | ------------ |
| English    | `app_en.arb` |
| Vietnamese | `app_vi.arb` |

Thêm hoặc chỉnh sửa bản dịch trong:

```text
lib/l10n/
```

Sau đó chạy:

```bash
flutter gen-l10n
```

---

# 📱 Supported Platforms

Hiện tại project tập trung vào ứng dụng mobile:

- Android
- iOS

Flutter cũng hỗ trợ Web và các nền tảng khác nếu cần mở rộng trong tương lai.

---

# 🔒 Security

Các thông tin nhạy cảm không nên được hard-code trực tiếp vào source code.

Frontend sử dụng:

- JWT Authentication
- Secure Local Storage
- Dio Interceptor
- HTTPS trong môi trường Production
- Backend Authorization
- Role-Based Access Control

---

# 📜 Main Commands

```bash
# Install dependencies
flutter pub get

# Generate localization
flutter gen-l10n

# Run application
flutter run

# Analyze source code
flutter analyze

# Run tests
flutter test

# Build release APK
flutter build apk --release
```

---

# 🤝 Development Workflow

```text
Create Branch
     │
     ▼
Develop Feature
     │
     ▼
flutter analyze
     │
     ▼
flutter test
     │
     ▼
Commit & Push
     │
     ▼
Create Pull Request
     │
     ▼
GitHub Actions
     │
     ▼
Merge
```

---

# 📄 License

This project is developed for educational and project purposes.
