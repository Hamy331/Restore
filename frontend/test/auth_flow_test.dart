import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/enums/user_role.dart';
import 'package:restore/modules/auth/auth_route_guard.dart';
import 'package:restore/modules/auth/bloc/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_event.dart';
import 'package:restore/modules/auth/bloc/auth_state.dart';
import 'package:restore/modules/auth/data/auth_mock_data.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/data/models/user_model.dart';

/// Secure storage giả trong bộ nhớ (giống token_storage_test)
Map<String, String> _fakeSecureStorage() {
  final values = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final key = args['key'] as String?;
          switch (call.method) {
            case 'write':
              values[key!] = args['value'] as String;
            case 'read':
              return values[key];
            case 'delete':
              values.remove(key);
          }
          return null;
        },
      );
  return values;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const user = UserModel(
    id: 'u1',
    email: 'a@b.c',
    fullName: 'A',
    username: 'a',
  );

  group('authRouteRedirect', () {
    test('đang kiểm tra phiên: giữ ở /splash và nhớ trang định vào', () {
      expect(
        authRouteRedirect(const AuthChecking(), Uri.parse('/account')),
        '/splash?from=%2Faccount',
      );
      expect(
        authRouteRedirect(const AuthChecking(), Uri.parse('/splash')),
        isNull,
      );
    });

    test(
      'mở app: đã đăng nhập về Home hoặc trang định vào, chưa thì Welcome',
      () {
        const signedIn = AuthAuthenticated(user);
        expect(authRouteRedirect(signedIn, Uri.parse('/splash')), '/home');
        expect(
          authRouteRedirect(signedIn, Uri.parse('/splash?from=%2Faccount')),
          '/account',
        );
        expect(
          authRouteRedirect(const AuthUnauthenticated(), Uri.parse('/splash')),
          '/welcome',
        );
        expect(
          authRouteRedirect(
            const AuthUnauthenticated(),
            Uri.parse('/splash?from=%2Flistings%2Fx1'),
          ),
          '/listings/x1',
        );
      },
    );

    test(
      'chưa đăng nhập vào trang cần tài khoản: sang /login, xong quay lại',
      () {
        const guest = AuthUnauthenticated();
        expect(authRouteRedirect(guest, Uri.parse('/home')), isNull);
        expect(
          authRouteRedirect(guest, Uri.parse('/account')),
          '/login?from=%2Faccount',
        );
        expect(
          authRouteRedirect(
            const AuthAuthenticated(user),
            Uri.parse('/login?from=%2Faccount'),
          ),
          '/account',
        );
        expect(
          authRouteRedirect(
            const AuthAuthenticated(user),
            Uri.parse('/welcome'),
          ),
          '/home',
        );
      },
    );

    test('bỏ from trỏ ra ngoài app hoặc về trang auth', () {
      const signedIn = AuthAuthenticated(user);
      expect(
        authRouteRedirect(signedIn, Uri.parse('/login?from=//evil.com')),
        '/home',
      );
      expect(
        authRouteRedirect(signedIn, Uri.parse('/login?from=%2Fwelcome')),
        '/home',
      );
    });
  });

  group('MockAuthRepository + AuthBloc', () {
    late Map<String, String> storage;
    setUp(() => storage = _fakeSecureStorage());

    test('đăng nhập xong mở lại app vẫn còn phiên (luôn ghi nhớ)', () async {
      final repository = MockAuthRepository(latency: Duration.zero);
      final signedIn = await repository.login(
        'MinhAnh@example.com',
        AuthMockData.password,
      );
      expect(signedIn.fullName, 'Nguyễn Minh Anh');
      expect(storage, isNotEmpty);

      // "Mở lại app": bloc mới, repository mới, cùng storage
      final bloc = AuthBloc(MockAuthRepository(latency: Duration.zero))
        ..add(const AuthCheckRequested());
      await expectLater(
        bloc.stream,
        emits(
          isA<AuthAuthenticated>().having((s) => s.user.id, 'id', 'user_me'),
        ),
      );
      await bloc.close();
    });

    test('sai mật khẩu báo lỗi, đăng xuất xóa phiên', () async {
      final repository = MockAuthRepository(latency: Duration.zero);
      await expectLater(
        repository.login('minhanh@example.com', 'sai'),
        throwsA(isA<AuthException>()),
      );
      final admin = await repository.login(
        'admin@restore.vn',
        AuthMockData.password,
      );
      expect(admin.role, UserRole.admin);
      await repository.logout();
      expect(storage, isEmpty);
      expect(await repository.restoreSession(), isNull);
    });

    test('đăng ký, xác minh OTP thì đăng nhập luôn', () async {
      final repository = MockAuthRepository(latency: Duration.zero);
      await repository.register(
        email: 'new@restore.vn',
        password: AuthMockData.password,
        username: 'new_user',
        fullName: 'Người Mới',
      );
      await expectLater(
        repository.login('new@restore.vn', AuthMockData.password),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'EMAIL_NOT_VERIFIED',
          ),
        ),
      );
      final verified = await repository.verifyRegistrationOtp(
        'new@restore.vn',
        AuthMockData.otp,
      );
      expect(verified.fullName, 'Người Mới');
      expect((await repository.restoreSession())?.email, 'new@restore.vn');
    });

    test('ApiClient báo hết phiên thì AuthBloc về chưa đăng nhập', () async {
      final expired = StreamController<void>();
      final bloc = AuthBloc(
        MockAuthRepository(latency: Duration.zero),
        sessionExpired: expired.stream,
      )..add(const LoggedIn(user));
      await expectLater(bloc.stream, emits(isA<AuthAuthenticated>()));
      expired.add(null);
      await expectLater(
        bloc.stream,
        emits(const AuthUnauthenticated(sessionExpired: true)),
      );
      await bloc.close();
      await expired.close();
    });
  });
}
