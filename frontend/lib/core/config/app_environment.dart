import 'package:flutter/foundation.dart';

/// Cấu hình lúc build, đọc từ file `env/<tên>.json` qua
/// `flutter run --dart-define-from-file=env/dev.json`.
///
/// Đây là nơi DUY NHẤT trong app đọc `String/bool.fromEnvironment`. Thêm khoá
/// mới thì khai báo ở đây, thêm vào `env/env.example.json` và các file env.
/// Không để khoá bí mật (VD khoá ZaloPay) ở đây: mọi thứ build vào app đều
/// đọc ngược ra được, khoá chỉ nằm ở backend.
class AppEnvironment {
  AppEnvironment._();

  /// Tên môi trường (dev, prod...), chỉ để hiển thị và ghi log
  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Dùng repository dữ liệu mẫu thay vì gọi backend. Mặc định tắt.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  /// Mở trang `/admin-preview` (giao diện admin dữ liệu mẫu) ở bản release.
  /// Bản debug luôn mở.
  static const bool _adminPreviewDefine = bool.fromEnvironment(
    'ENABLE_ADMIN_PREVIEW',
    defaultValue: false,
  );

  static bool get enableAdminPreview => kDebugMode || _adminPreviewDefine;

  /// Hiện nút TEST đổi gói ở trang chủ (xem DevPlanOverride)
  static const bool devPlanSwitch = bool.fromEnvironment(
    'DEV_PLAN_SWITCH',
    defaultValue: false,
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }

    return 'http://localhost:3000/api/v1';
  }
}
