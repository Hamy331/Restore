import 'bloc/auth_state.dart';

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

const guestOnlyAuthPaths = {'/welcome', '/login', '/register', '/verify-email'};

bool isPublicAuthPath(String path) => publicAuthPaths.contains(path);

bool isPublicRoute(String path) {
  if (isPublicAuthPath(path) || path == '/home' || path == '/search') {
    return true;
  }

  return RegExp(r'^/listings/[^/]+$').hasMatch(path) ||
      RegExp(r'^/seller/[^/]+$').hasMatch(path) ||
      RegExp(r'^/seller/[^/]+/reviews$').hasMatch(path);
}

String? authRouteRedirect(AuthState authState, String path) {
  final isPublic = isPublicRoute(path);
  if (authState is AuthUnauthenticated && !isPublic) return '/login';
  if (authState is AuthAuthenticated) {
    if (path.startsWith('/admin') && !authState.isAdmin) return '/home';
    if (guestOnlyAuthPaths.contains(path)) {
      return '/home';
    }
  }
  return null;
}
