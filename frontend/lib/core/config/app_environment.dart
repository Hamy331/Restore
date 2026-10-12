import 'package:flutter/foundation.dart';

class AppEnvironment {
  AppEnvironment._();

  static const _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Dùng dữ liệu mẫu thay cho API ở các tính năng backend chưa làm xong
  /// (danh mục, địa chỉ, tin đăng). Chạy với
  /// `--dart-define=USE_MOCK_DATA=false` để gọi API thật.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }

    return 'http://localhost:3000/api/v1';
  }
}
