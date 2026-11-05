import '../bloc/auth/auth_state.dart';

/// Trang chờ lúc khôi phục phiên đã lưu
const splashPath = '/splash';

const publicAuthPaths = {
  '/welcome',
  '/login',
  '/register',
  '/verify-email',
  '/email-verified',
  '/forgot-password',
  '/forgot-password/otp',
  '/reset-password',
  '/password-reset-success',
};

/// Đã đăng nhập thì không vào lại các trang này
const guestOnlyAuthPaths = {
  '/welcome',
  '/login',
  '/register',
  '/verify-email',
  '/email-verified',
};

bool isPublicAuthPath(String path) => publicAuthPaths.contains(path);

/// Khách chưa đăng nhập vẫn xem được: trang auth, trang chủ, tìm kiếm, chi tiết tin, trang người bán
bool isPublicRoute(String path) {
  if (isPublicAuthPath(path) ||
      path == '/home' ||
      path == '/search' ||
      path == '/blog') {
    return true;
  }

  return RegExp(r'^/listings/[^/]+$').hasMatch(path) ||
      RegExp(r'^/seller/[^/]+$').hasMatch(path) ||
      RegExp(r'^/seller/[^/]+/reviews$').hasMatch(path);
}

/// Toàn bộ điều hướng theo trạng thái đăng nhập (router gọi lại mỗi khi AuthBloc đổi state).
///
/// - Đang khôi phục phiên: giữ ở /splash, nhớ trang đang định vào trong `?from=`.
/// - Chưa đăng nhập mà vào trang cần tài khoản: sang /login?from=..., đăng nhập
///   xong quay lại đúng trang đó.
/// - Đã đăng nhập mà ở trang dành cho khách: về `from`, hoặc /admin (admin) / /home.
/// - Không phải admin mà vào /admin...: về /home.
String? authRouteRedirect(AuthState authState, Uri uri) {
  final path = uri.path;
  final from = _safeFrom(uri.queryParameters['from']);

  if (authState is AuthChecking) {
    if (path == splashPath) return null;
    return _withFrom(splashPath, uri.toString());
  }

  if (authState is AuthAuthenticated) {
    // Trang quản trị chỉ dành cho admin
    if (path.startsWith('/admin') && !authState.isAdmin) return '/home';
    if (path == splashPath || guestOnlyAuthPaths.contains(path)) {
      return from ?? (authState.isAdmin ? '/admin' : '/home');
    }
    return null;
  }

  // Chưa đăng nhập
  if (path == splashPath) {
    return from != null && isPublicRoute(Uri.parse(from).path)
        ? from
        : '/welcome';
  }
  if (!isPublicRoute(path)) return _withFrom('/login', uri.toString());
  return null;
}

/// Trang đăng nhập, đăng nhập xong quay lại [from]
String loginPath({String? from}) =>
    from == null ? '/login' : _withFrom('/login', from);

String _withFrom(String path, String from) =>
    Uri(path: path, queryParameters: {'from': from}).toString();

/// Chỉ nhận đường dẫn trong app, bỏ trang auth / splash để không lặp
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final path = Uri.parse(from).path;
  if (path == splashPath || guestOnlyAuthPaths.contains(path)) return null;
  return from;
}
