import 'package:flutter/foundation.dart';

class AppEnvironment {
  AppEnvironment._();

  static const _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Luồng chạy app luôn lấy dữ liệu thật từ backend. Repository mẫu chỉ dùng trong test.
  static const bool useMockData = false;

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }

    return 'http://localhost:3000/api/v1';
  }
}
