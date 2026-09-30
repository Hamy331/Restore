import 'package:dio/dio.dart';
import 'package:restore/core/constants/app_constants.dart';
import '../../services/token_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  final TokenStorage tokenStorage = TokenStorage();
  Future<bool>? _refreshFuture;

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
          final refreshed = await pendingRefresh;
          if (identical(_refreshFuture, pendingRefresh)) _refreshFuture = null;
          if (!refreshed) return handler.next(error);

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

  Future<bool> _refreshTokens() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await tokenStorage.clear();
      return false;
    }

    try {
      final refreshClient = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
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
      return true;
    } catch (_) {
      await tokenStorage.clear();
      return false;
    }
  }

  Future<bool> refreshSession() => _refreshTokens();
}
