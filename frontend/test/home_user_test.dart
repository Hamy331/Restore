import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/routes/app_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_event.dart';
import 'package:restore/modules/auth/data/auth_mock_data.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';

/// Mở app với AuthBloc dùng tài khoản mẫu, token lưu trong bộ nhớ
Future<(AuthBloc, GoRouter, MockAuthRepository)> _openApp(
  WidgetTester tester,
) async {
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
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // Font Ahem của môi trường test rộng hơn font thật nên dòng khu vực trên
  // thẻ tin bị tràn vài px; bỏ qua riêng lỗi này
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
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
  return (bloc, router, repo);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'khách xem trang chủ: lời chào chung, bấm lưu tin thì sang đăng nhập',
    (tester) async {
      final (_, router, _) = await _openApp(tester);
      router.go('/home');
      await _settle(tester);
      expect(find.text('Chào bạn 👋'), findsOneWidget);

      // Thẻ tin nằm dưới banner: cuộn tới nút lưu tin đầu tiên rồi bấm
      final favorite = find
          .byWidgetPredicate(
            (w) =>
                w is Icon &&
                (w.icon == AppIcons.favorite ||
                    w.icon == AppIcons.favoriteActive),
            skipOffstage: false,
          )
          .first;
      await tester.ensureVisible(favorite);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(favorite);
      await _settle(tester);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/login?from=%2Fhome',
      );
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'đăng nhập rồi đăng xuất: trang chủ và tài khoản theo người dùng của AuthBloc',
    (tester) async {
      final (bloc, router, repo) = await _openApp(tester);
      router.go('/home');
      await _settle(tester);
      expect(find.text('Chào bạn 👋'), findsOneWidget);

      final user = (await tester.runAsync(
        () => repo.login('minhanh@example.com', AuthMockData.password),
      ))!;
      bloc.add(LoggedIn(user));
      await _settle(tester);
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.textContaining('Anh 👋'), findsOneWidget);

      // Trang tài khoản hiện đúng người đang đăng nhập
      router.go('/account');
      await _settle(tester);
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      expect(find.text('NA'), findsOneWidget);
      expect(find.text('Thành viên từ 2022'), findsOneWidget);
      expect(find.text('090 ••• 1234'), findsOneWidget);

      await tester.runAsync(() => repo.logout());
      bloc.add(const LoggedOut());
      await _settle(tester);
      router.go('/home');
      await _settle(tester);
      expect(find.text('Chào bạn 👋'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
