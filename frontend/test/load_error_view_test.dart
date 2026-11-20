import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/home/models/home_banner.dart';
import 'package:restore/modules/home/repositories/home_repository.dart';
import 'package:restore/modules/home/views/home/home_view.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';

import 'support/load_test_fonts.dart';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('vi')],
  theme: AppTheme.lightTheme,
  home: Scaffold(body: child),
);

/// Lần đầu lỗi, lần sau tải được
class _FlakyHomeRepository extends MockHomeRepository {
  _FlakyHomeRepository() : super(latency: Duration.zero);

  int calls = 0;

  @override
  Future<List<HomeBanner>> getBanners() async {
    calls++;
    if (calls == 1) throw Exception('offline');
    return super.getBanners();
  }
}

void main() {
  // Font thật để chữ không bị tràn như font Ahem mặc định của test
  setUpAll(loadTestFonts);

  testWidgets('dùng bộ chuỗi chung khi không truyền title/message', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(AppLoadErrorView(onRetry: () {})));
    await tester.pumpAndSettle();

    expect(find.text('Chưa tải được dữ liệu'), findsOneWidget);
    expect(find.text('Kiểm tra kết nối mạng rồi thử lại nhé.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('không có onRetry thì không hiện nút Thử lại', (tester) async {
    await tester.pumpWidget(_wrap(const AppLoadErrorView(title: 'Lỗi riêng')));
    await tester.pumpAndSettle();

    expect(find.text('Lỗi riêng'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('nút Thử lại hiện loading tới khi Future xong', (tester) async {
    final completer = Completer<void>();
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        AppLoadErrorView(
          onRetry: () {
            taps++;
            return completer.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
    expect(find.text('Thử lại'), findsNothing);

    // Đang chờ thì bấm thêm cũng không gọi lại
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('trang Home lỗi hiện AppLoadErrorView, bấm Thử lại thì tải lại', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = _FlakyHomeRepository();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(MockAuthRepository(latency: Duration.zero)),
          ),
          BlocProvider(
            create: (_) => UserAreaCubit(
              locationRepository: MockLocationRepository(
                latency: Duration.zero,
              ),
            )..selectNationwide(),
          ),
        ],
        child: _wrap(
          HomeView(
            homeRepository: repository,
            categoryRepository: MockCategoryRepository(latency: Duration.zero),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(AppLoadErrorView), findsOneWidget);
    expect(find.text('Chưa tải được trang chủ'), findsOneWidget);
    expect(find.text('Kiểm tra kết nối mạng rồi thử lại nhé.'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(repository.calls, 2);
    expect(find.byType(AppLoadErrorView), findsNothing);
  });
}
