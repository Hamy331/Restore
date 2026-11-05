import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/services/token_storage.dart';

import '../data/auth_mock_data.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.code, this.field});
  final String message;
  final String? code;
  final String? field;

  @override
  String toString() => message;
}

/// Đăng ký, đăng nhập và giữ phiên.
///
/// Phiên luôn được ghi nhớ: access + refresh token lưu trong [TokenStorage]
/// (Keychain / Keystore / localStorage có mã hóa). Refresh token sống 60 ngày
/// và xoay vòng mỗi lần làm mới, nên người dùng còn mở app thì phiên tự gia hạn.
abstract class AuthRepository {
  /// App dùng API thật. Test có thể truyền repository mẫu trực tiếp.
  factory AuthRepository() => ApiAuthRepository();

  /// Đăng nhập và lưu phiên
  Future<UserModel> login(String email, String password);

  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  });

  /// Xác minh email bằng OTP; thành công thì đăng nhập luôn và lưu phiên
  Future<UserModel> verifyRegistrationOtp(String email, String otp);

  Future<void> resendRegistrationOtp(String email);

  Future<void> forgotPassword(String email);

  /// Trả về resetToken dùng cho [resetPassword]
  Future<String> verifyForgotPasswordOtp(String email, String otp);

  /// Đặt mật khẩu mới; mọi phiên cũ bị thu hồi nên xóa phiên trên máy
  Future<void> resetPassword(String resetToken, String newPassword);

  /// Người dùng lưu sẵn trên máy từ lần đăng nhập trước, đọc ngay lúc mở app
  /// (không gọi mạng). `null` nếu chưa đăng nhập.
  Future<UserModel?> cachedUser();

  /// Hỏi máy chủ phiên đã lưu còn dùng được không và lấy thông tin người dùng mới nhất.
  /// Mất mạng thì trả về [cachedUser] (vẫn coi là đăng nhập); `null` nếu chưa
  /// đăng nhập hoặc máy chủ từ chối phiên.
  Future<UserModel?> restoreSession();

  /// Đăng xuất; phiên trên máy luôn bị xóa kể cả khi mất mạng
  Future<void> logout();
}

/// Gọi API /auth của backend
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  TokenStorage get _tokens => _apiClient.tokenStorage;

  @override
  Future<UserModel> login(String email, String password) =>
      _guard('Không thể đăng nhập.', () async {
        final data = await _post('/auth/login', {
          'email': email.trim(),
          'password': password,
        });
        await _storeTokens(data);
        return _user(data['user']);
      });

  @override
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) => _guard('Không thể đăng ký.', () async {
    await _post('/auth/register', {
      'email': email.trim(),
      'password': password,
      'username': username.trim(),
      'fullName': fullName.trim(),
    });
  });

  @override
  Future<UserModel> verifyRegistrationOtp(String email, String otp) =>
      _guard('Không thể xác minh OTP.', () async {
        final data = await _post('/auth/verify-registration-otp', {
          'email': email.trim(),
          'otp': otp.trim(),
        });
        await _storeTokens(data);
        return _user(data['user']);
      });

  @override
  Future<void> resendRegistrationOtp(String email) =>
      _guard('Không thể gửi lại OTP.', () async {
        await _post('/auth/resend-registration-otp', {'email': email.trim()});
      });

  @override
  Future<void> forgotPassword(String email) =>
      _guard('Không thể gửi OTP.', () async {
        await _post('/auth/forgot-password', {'email': email.trim()});
      });

  @override
  Future<String> verifyForgotPasswordOtp(String email, String otp) =>
      _guard('Không thể xác minh OTP.', () async {
        final data = await _post('/auth/verify-otp', {
          'email': email.trim(),
          'otp': otp.trim(),
        });
        final resetToken = data['resetToken'];
        if (resetToken is! String || resetToken.isEmpty) {
          throw const FormatException();
        }
        return resetToken;
      });

  @override
  Future<void> resetPassword(String resetToken, String newPassword) =>
      _guard('Không thể đặt lại mật khẩu.', () async {
        await _post('/auth/reset-password', {
          'resetToken': resetToken,
          'newPassword': newPassword,
        });
        await _tokens.clear();
      });

  @override
  Future<UserModel?> cachedUser() => _readCachedUser(_tokens);

  @override
  Future<UserModel?> restoreSession() async {
    final access = await _tokens.readAccessToken();
    final refresh = await _tokens.readRefreshToken();
    if (_isEmpty(access) && _isEmpty(refresh)) return null;
    // Chỉ còn refresh token (VD access token bị xóa): làm mới trước khi gọi /auth/me
    if (_isEmpty(access) && !await _apiClient.refreshSession()) return null;
    try {
      // 401 vì access token hết hạn: interceptor tự refresh rồi gọi lại
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/auth/me',
      );
      final user = _user(_data(response));
      await _tokens.writeUser(user.toJson());
      return user;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        await _tokens.clear();
        return null;
      }
      // Mất mạng / máy chủ lỗi: giữ phiên, dùng người dùng đã lưu
      return cachedUser();
    } on FormatException {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
    try {
      if (!_isEmpty(refreshToken)) {
        await _apiClient.dio.post<Map<String, dynamic>>(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } on DioException {
      // Đăng xuất trên máy luôn phải xong, kể cả khi không gọi được API
    } finally {
      await _tokens.clear();
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      path,
      data: body,
    );
    final data = response.data?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return Map<String, dynamic>.from(data);
  }

  UserModel _user(Object? json) {
    if (json is! Map) throw const FormatException('Missing user');
    return UserModel.fromJson(Map<String, dynamic>.from(json));
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is! String || refresh is! String) throw const FormatException();
    await _tokens.writeTokens(accessToken: access, refreshToken: refresh);
    await _tokens.writeUser(_user(data['user']).toJson());
  }

  /// Đổi lỗi Dio / phản hồi sai dạng thành [AuthException] có thông báo cho người dùng
  Future<T> _guard<T>(String fallback, Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map) {
        throw AuthException(
          body['error'] is String ? body['error'] as String : fallback,
          code: body['code'] as String?,
          field: body['field'] as String?,
        );
      }
      throw const AuthException(
        'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.',
        code: 'NETWORK_ERROR',
      );
    } on FormatException {
      throw const AuthException('Phản hồi từ máy chủ không hợp lệ.');
    }
  }

  static bool _isEmpty(String? value) => value == null || value.isEmpty;
}

/// Đăng nhập bằng tài khoản mẫu, không cần backend.
///
/// Tài khoản: xem [AuthMockData.accounts] (mật khẩu chung [AuthMockData.password]),
/// mọi OTP là [AuthMockData.otp]. Phiên vẫn lưu trong [TokenStorage] nên
/// ghi nhớ đăng nhập giống bản thật.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    TokenStorage? tokenStorage,
    this.latency = const Duration(milliseconds: 400),
  }) : _tokens = tokenStorage ?? TokenStorage();

  final TokenStorage _tokens;
  final Duration latency;

  /// Tài khoản đăng ký mới trong phiên chạy app: email → user
  static final Map<String, Map<String, dynamic>> _registered = {};

  static Map<String, dynamic>? _account(String email) {
    final key = email.trim().toLowerCase();
    return _registered[key] ??
        AuthMockData.accounts.where((user) => user['email'] == key).firstOrNull;
  }

  Future<UserModel> _signIn(Map<String, dynamic> account) async {
    await _tokens.writeTokens(
      accessToken: '${AuthMockData.tokenPrefix}${account['email']}',
      refreshToken: '${AuthMockData.tokenPrefix}${account['email']}',
    );
    await _tokens.writeUser(account);
    return UserModel.fromJson(account);
  }

  @override
  Future<UserModel?> cachedUser() => _readCachedUser(_tokens);

  @override
  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(latency);
    final account = _account(email);
    if (account == null || password != AuthMockData.password) {
      throw const AuthException(
        'Email hoặc mật khẩu không chính xác.',
        code: 'INVALID_CREDENTIALS',
      );
    }
    if (account['status'] == 'UNVERIFIED') {
      throw const AuthException(
        'Vui lòng xác minh email trước khi đăng nhập.',
        code: 'EMAIL_NOT_VERIFIED',
      );
    }
    return _signIn(account);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    await Future<void>.delayed(latency);
    final key = email.trim().toLowerCase();
    if (_account(key) != null) {
      throw const AuthException(
        'Email đã được sử dụng.',
        code: 'EMAIL_EXISTS',
        field: 'email',
      );
    }
    _registered[key] = {
      'id': 'user_${_registered.length + 1}',
      'email': key,
      'fullName': fullName.trim(),
      'username': username.trim(),
      'role': 'USER',
      'status': 'UNVERIFIED',
    };
  }

  @override
  Future<UserModel> verifyRegistrationOtp(String email, String otp) async {
    await Future<void>.delayed(latency);
    final account = _account(email);
    if (account == null) {
      throw const AuthException('Không tìm thấy tài khoản.');
    }
    _checkOtp(otp);
    final verified = {...account, 'status': 'ACTIVE'};
    _registered[account['email'] as String] = verified;
    return _signIn(verified);
  }

  @override
  Future<void> resendRegistrationOtp(String email) =>
      Future<void>.delayed(latency);

  @override
  Future<void> forgotPassword(String email) => Future<void>.delayed(latency);

  @override
  Future<String> verifyForgotPasswordOtp(String email, String otp) async {
    await Future<void>.delayed(latency);
    _checkOtp(otp);
    return 'mock-reset-token';
  }

  @override
  Future<void> resetPassword(String resetToken, String newPassword) async {
    await Future<void>.delayed(latency);
    await _tokens.clear();
  }

  @override
  Future<UserModel?> restoreSession() async {
    final token = await _tokens.readRefreshToken();
    if (token == null || !token.startsWith(AuthMockData.tokenPrefix)) {
      return null;
    }
    final account = _account(token.substring(AuthMockData.tokenPrefix.length));
    if (account == null) {
      await _tokens.clear();
      return null;
    }
    await _tokens.writeUser(account);
    return UserModel.fromJson(account);
  }

  @override
  Future<void> logout() => _tokens.clear();

  void _checkOtp(String otp) {
    if (otp.trim() != AuthMockData.otp) {
      throw const AuthException('Mã OTP không chính xác.', code: 'INVALID_OTP');
    }
  }
}

/// Người dùng đã lưu, chỉ khi máy còn giữ phiên (còn refresh hoặc access token)
Future<UserModel?> _readCachedUser(TokenStorage tokens) async {
  final refresh = await tokens.readRefreshToken();
  final access = await tokens.readAccessToken();
  if ((refresh == null || refresh.isEmpty) &&
      (access == null || access.isEmpty)) {
    return null;
  }
  final json = await tokens.readUser();
  if (json == null) return null;
  try {
    return UserModel.fromJson(json);
  } catch (_) {
    return null;
  }
}
