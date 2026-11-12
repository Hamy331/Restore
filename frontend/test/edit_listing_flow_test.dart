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
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/auth/data/auth_mock_data.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';
import 'package:restore/modules/listings/repositories/posting_quota_repository.dart';

/// Mở app (dữ liệu mẫu) đã đăng nhập
Future<GoRouter> _openSignedIn(WidgetTester tester) async {
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
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
  final repo = MockAuthRepository(latency: Duration.zero);
  final bloc = AuthBloc(repo)..add(const AuthCheckRequested());
  await tester.runAsync(() => bloc.stream.first);
  final user = (await tester.runAsync(
    () => repo.login('minhanh@example.com', AuthMockData.password),
  ))!;
  bloc.add(LoggedIn(user));
  final router = createAppRouter(
    bloc,
    createListing: CreateListingRepositories(
      listings: MockListingsRepository(),
      categories: MockCategoryRepository(),
      postingQuota: MockPostingQuotaRepository(),
      location: MockLocationRepository(),
    ),
  );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        // Không định vị trong test: nút khu vực hiện "Toàn quốc"
        BlocProvider(
          create: (_) => UserAreaCubit(
            locationRepository: MockLocationRepository(latency: Duration.zero),
          )..selectNationwide(),
        ),
      ],
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
  return router;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

Future<void> _settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'sửa tin đã duyệt: mở bước 2 có thông báo, không lưu nháp, thoát thì hỏi bỏ thay đổi',
    (tester) async {
      final router = await _openSignedIn(tester);
      router.go('/home');
      await _settle(tester);
      router.push('/create-listing/edit/l1');
      await _settle(tester);
      expect(_path(router), '/create-listing/basic-info');
      expect(find.text('Sửa tin đăng'), findsOneWidget);
      expect(
        find.textContaining('Người mua vẫn thấy bản hiện tại'),
        findsOneWidget,
      );
      expect(
        find.text('Tin đã duyệt không đổi được chuyên mục.'),
        findsOneWidget,
      );
      expect(find.text('Lưu nháp'), findsNothing);
      expect(
        find.widgetWithText(TextField, 'Máy ảnh Canon AE-1 kèm lens 50mm f1.8'),
        findsOneWidget,
      );

      // Chưa sửa gì: thoát luôn
      await tester.tap(find.byIcon(AppIcons.back).first);
      await _settle(tester);
      expect(_path(router), '/home');

      // Sửa rồi thoát: hỏi bỏ thay đổi (không hỏi lưu nháp)
      router.push('/create-listing/edit/l1');
      await _settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Máy ảnh Canon AE-1 kèm lens 50mm f1.8'),
        'Máy ảnh Canon AE-1 đã sửa',
      );
      await _settle(tester, 3);
      await tester.tap(find.byIcon(AppIcons.back).first);
      await _settle(tester);
      expect(find.text('Bỏ các thay đổi?'), findsOneWidget);
      expect(find.text('Lưu tin trước khi thoát?'), findsNothing);
      await tester.tap(find.text('Sửa tiếp'));
      await _settle(tester);
      expect(_path(router), '/create-listing/basic-info');

      await tester.tap(find.byIcon(AppIcons.back).first);
      await _settle(tester);
      await tester.tap(find.text('Bỏ thay đổi'));
      await _settle(tester);
      expect(_path(router), '/home');
      final listing = await tester.runAsync(
        () => MockListingsRepository(latency: Duration.zero).getOwned('l1'),
      );
      expect(listing!.pendingEdit, isNull);
      await tester.pump(const Duration(seconds: 2));
      // Gỡ cây widget trước khi trả lại kích thước màn hình (ScreenUtil còn
      // nghe đổi kích thước sẽ báo lỗi khi cây đã bị gỡ)
      await tester.pumpWidget(const SizedBox());
    },
  );
}
