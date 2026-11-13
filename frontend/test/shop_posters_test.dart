import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/shop_posters/bloc/poster_editor_cubit.dart';
import 'package:restore/modules/shop_posters/models/shop_poster.dart';
import 'package:restore/modules/shop_posters/models/shop_poster_overview.dart';
import 'package:restore/modules/shop_posters/repositories/shop_poster_repository.dart';
import 'package:restore/modules/shop_posters/views/poster_editor/poster_editor_view.dart';
import 'package:restore/modules/shop_posters/views/shop_posters/shop_posters_view.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

const _limits = PosterLimits(
  activeLimit: 2,
  monthlyLimit: 4,
  usedThisMonth: 0,
  slotsInUse: 0,
);

void main() {
  testWidgets('lists posters with status, reject reason, filters and stop', (
    tester,
  ) async {
    await _pump(
      tester,
      ShopPostersView(
        repository: MockShopPosterRepository(latency: Duration.zero),
      ),
    );
    expect(find.text('Poster shop'), findsOneWidget);
    expect(find.byKey(const ValueKey('poster-quota-slots')), findsOneWidget);
    expect(find.text('Galaxy Week giảm tới 20%'), findsOneWidget);
    expect(find.text('Thu cũ đổi mới'), findsOneWidget);
    expect(find.textContaining('Quá nhiều chữ trên ảnh'), findsOneWidget);
    expect(find.text('Sửa và gửi lại'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('poster-filter-rejected')),
    );
    await tester.tap(find.byKey(const ValueKey('poster-filter-rejected')));
    await tester.pump();
    expect(find.text('Galaxy Week giảm tới 20%'), findsNothing);
    expect(find.text('Thu cũ đổi mới'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('poster-filter-all')));
    await tester.tap(find.byKey(const ValueKey('poster-filter-all')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('poster-stop-poster-running')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const ValueKey('poster-stop-confirm')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Đã dừng'), findsWidgets);
    expect(
      find.byKey(const ValueKey('poster-stop-poster-running')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-store plan sees the upgrade prompt', (tester) async {
    await _pump(
      tester,
      ShopPostersView(
        repository: MockShopPosterRepository(
          latency: Duration.zero,
          activeLimit: 0,
          posters: [],
        ),
      ),
    );
    expect(find.text('Poster dành cho gói Cửa hàng'), findsOneWidget);
    expect(find.text('Xem gói'), findsOneWidget);
    expect(find.byKey(const ValueKey('poster-create')), findsNothing);
  });

  testWidgets('editor shows errors when sending an empty poster', (
    tester,
  ) async {
    await _pump(
      tester,
      PosterEditorView(
        args: PosterEditorArgs(
          limits: _limits,
          repository: MockShopPosterRepository(latency: Duration.zero),
        ),
      ),
    );
    expect(find.text('Tạo poster'), findsOneWidget);
    expect(find.text('7 ngày'), findsWidgets);
    await tester.tap(find.text('Gửi duyệt'));
    await tester.pump();
    expect(find.text('Hãy chọn ảnh poster.'), findsOneWidget);
    expect(find.text('Hãy nhập tên chương trình.'), findsOneWidget);

    await tester.tap(find.text('Mở một tin'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Gửi duyệt'));
    await tester.pump();
    expect(find.text('Hãy chọn tin.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('editor sends a cropped poster and respects poster slots', () async {
    final repository = MockShopPosterRepository(
      latency: Duration.zero,
      posters: [],
    );
    final png = Uint8List.fromList([1, 2, 3]);
    PosterEditorCubit editor() =>
        PosterEditorCubit(repository: repository, limits: _limits);

    final cubit = editor()..setTitle('Sale 11.11');
    expect(cubit.state.valid, isFalse);
    cubit.setImage(png, source: png);
    expect(cubit.state.valid, isTrue);
    cubit.setDays(30);
    expect(cubit.state.days, 14);

    final first = await cubit.submit();
    expect(first, isA<PosterSubmitted>());
    expect((first! as PosterSubmitted).poster.state, ShopPosterState.pending);

    final second = editor()
      ..setTitle('Sale 2')
      ..setImage(png);
    expect(await second.submit(), isA<PosterSubmitted>());

    final third = editor()
      ..setTitle('Sale 3')
      ..setImage(png);
    final full = await third.submit();
    expect((full! as PosterSubmitFailed).code, 'POSTER_SLOT_FULL');

    // hẹn sau khi hai poster kia kết thúc thì còn suất
    third.setStartsAt(DateTime.now().add(const Duration(days: 15)));
    expect(await third.submit(), isA<PosterSubmitted>());
  });
}
