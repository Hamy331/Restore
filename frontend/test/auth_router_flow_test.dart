import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/routes/app_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_event.dart';
import 'package:restore/modules/auth/data/auth_mock_data.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/auth/views/welcome/welcome_view.dart';
import 'package:restore/modules/auth/views/login/login_view.dart';

void main() {
  testWidgets(
    'mở app chưa đăng nhập → Welcome; vào trang cần tài khoản → Login; đăng nhập xong quay lại đúng trang',
    (tester) async {
      final values = <String, String>{};
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          final a = Map<String, dynamic>.from(call.arguments as Map);
          if (call.method == 'write') values[a['key']] = a['value'];
          if (call.method == 'read') return values[a['key']];
          if (call.method == 'delete') values.remove(a['key']);
          return null;
        },
      );
      final repo = MockAuthRepository(latency: Duration.zero);
      final bloc = AuthBloc(repo)..add(const AuthCheckRequested());
      await tester.runAsync(() => bloc.stream.first);
      final router = createAppRouter(bloc);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('vi')],
              locale: const Locale('vi'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WelcomeView), findsOneWidget);
      router.go('/account');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/login?from=%2Faccount',
      );
      expect(find.byType(LoginView), findsOneWidget);
      final user = (await tester.runAsync(
        () => repo.login('minhanh@example.com', AuthMockData.password),
      ))!;
      bloc.add(LoggedIn(user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.routeInformationProvider.value.uri.path, '/account');
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
