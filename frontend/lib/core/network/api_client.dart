import 'dart:async';

import 'package:dio/dio.dart';
import 'package:restore/core/constants/app_constants.dart';
import '../../services/token_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  final TokenStorage tokenStorage = TokenStorage();
  Future<_RefreshResult>? _refreshFuture;
  final _sessionExpired = StreamController<void>.broadcast();

  /// Phát khi refresh token hết hạn hoặc bị thu hồi (đã xóa token trên máy).
  /// AuthBloc nghe để chuyển về trạng thái chưa đăng nhập.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    final options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: const {'Accept': 'application/json'},
    );
    dio = Dio(options);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final canRefresh =
              error.response?.statusCode == 401 &&
              request.extra['authRetried'] != true &&
              (!request.path.startsWith('/auth/') ||
                  request.path == '/auth/me') &&
              request.headers['Authorization'] != null;
          if (!canRefresh) return handler.next(error);

          final pendingRefresh = _refreshFuture ??= _refreshTokens();
          final result = await pendingRefresh;
          if (identical(_refreshFuture, pendingRefresh)) _refreshFuture = null;
          if (result != _RefreshResult.refreshed) return handler.next(error);

          request.extra['authRetried'] = true;
          request.headers['Authorization'] =
              'Bearer ${await tokenStorage.readAccessToken()}';
          try {
            handler.resolve(await dio.fetch<dynamic>(request));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  /// Đổi refresh token lấy cặp token mới.
  ///
  /// - Máy chủ từ chối (hết hạn, bị thu hồi): xóa phiên, báo [sessionExpired]
  ///   một lần (các request song song dùng chung lượt refresh này).
  /// - Mất mạng / máy chủ lỗi: giữ phiên để thử lại sau, [_RefreshResult.offline].
  Future<_RefreshResult> _refreshTokens() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await tokenStorage.clear();
      return _RefreshResult.rejected;
    }

    try {
      final refreshClient = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      // Refresh token xoay vòng: mỗi lần làm mới, phiên được gia hạn thêm 60 ngày
      final response = await refreshClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final access = data?['accessToken'] as String?;
      final refresh = data?['refreshToken'] as String?;
      if (access == null || refresh == null) throw const FormatException();
      await tokenStorage.writeTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return _RefreshResult.refreshed;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status != null && status >= 400 && status < 500) return _expire();
      return _RefreshResult.offline;
    } on FormatException {
      return _expire();
    }
  }

  Future<_RefreshResult> _expire() async {
    await tokenStorage.clear();
    _sessionExpired.add(null);
    return _RefreshResult.rejected;
  }

  /// Làm mới phiên ngay (dùng khi mở app mà chỉ còn refresh token)
  Future<bool> refreshSession() async =>
      await _refreshTokens() == _RefreshResult.refreshed;
}

enum _RefreshResult { refreshed, rejected, offline }
