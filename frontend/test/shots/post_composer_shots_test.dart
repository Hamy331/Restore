import 'package:restore/modules/feed/repositories/feed_post_repository.dart';
import 'package:restore/modules/feed/repositories/recent_photos_repository.dart';
import '../support/load_test_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/feed/bloc/post_composer/post_composer_cubit.dart';
import 'package:restore/modules/feed/bloc/post_composer/post_composer_state.dart';
import 'package:restore/modules/feed/data/feed_mock_data.dart';
import 'package:restore/modules/feed/views/feeds/feeds_view.dart';
import 'package:restore/modules/feed/views/post_composer/post_composer_mobile_view.dart';
import 'package:restore/modules/feed/views/post_composer/post_composer_view.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

Widget _app() {
  final router = GoRouter(
    initialLocation: FeedsView.path,
    routes: [
      GoRoute(path: FeedsView.path, builder: (_, _) => const FeedsView()),
      GoRoute(
        path: PostComposerView.path,
        builder: (_, state) => PostComposerView(
          openPhotos: state.uri.queryParameters['panel'] == 'photos',
          repository: MockFeedPostRepository(latency: Duration.zero),
          recentPhotosRepository: MockRecentPhotosRepository(),
        ),
      ),
    ],
  );
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    locale: const Locale('vi'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi')],
    theme: AppTheme.lightTheme,
    routerConfig: router,
  );
}

Future<void> _settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _precache(WidgetTester tester) async {
  final context = tester.element(find.byType(Navigator).first);
  await tester.runAsync(() async {
    for (final path in FeedMockData.recentPhotos) {
      await precacheImage(AssetImage(path), context);
    }
  });
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester, 10);
  // Ảnh asset chỉ giải mã khi chạy bất đồng bộ thật
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = (element.widget as Image).image;
      await precacheImage(image, element);
    }
  });
  await _settle(tester, 5);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('out/$name.png'),
  );
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('post composer shots', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await _settle(tester, 10);
    await _precache(tester);
    await _shot(tester, '1_bang_tin');

    // Bấm nút ảnh: mở thẳng lưới ảnh như Zalo
    await tester.tap(find.byTooltip('Ảnh').first);
    await _settle(tester, 15);
    await _shot(tester, '2_mo_luoi_anh');

    final cubit = tester
        .element(find.byType(PostComposerMobileView))
        .read<PostComposerCubit>();
    await tester.enterText(
      find.byType(TextField),
      'Dọn nhà nên pass lại máy ảnh film Canon AE-1, máy chạy ngon, '
      'ai quan tâm ib mình nhé!',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    cubit.openPanel(PostComposerPanel.photos);
    cubit.togglePhoto(FeedMockData.recentPhotos[0]);
    cubit.togglePhoto(FeedMockData.recentPhotos[2]);
    cubit.togglePhoto(FeedMockData.recentPhotos[4]);
    await _shot(tester, '3_chon_anh');

    cubit.closePanel();
    FocusManager.instance.primaryFocus?.unfocus();
    final options = cubit.state.options;
    cubit
      ..setListing(options.myListings.first)
      ..setTopic(options.topics[1])
      ..toggleMention(options.mentionable[0])
      ..toggleMention(options.mentionable[1])
      ..setLocation(
        const AreaOption(
          code: '26734',
          name: 'Phường Sài Gòn',
          level: AdministrativeLevel.ward,
          parentName: 'TP. Hồ Chí Minh',
          center: GeoPoint(10.77, 106.70),
        ),
      );
    await _shot(tester, '4_gan_tin_va_chu_de');

    for (final photo in [...cubit.state.draft.photos]) {
      cubit.removePhoto(photo);
    }
    cubit.setListing(null);
    cubit.setLocation(null);
    await tester.enterText(
      find.byType(TextField),
      'Có ai biết chỗ sửa đồng hồ cơ uy tín ở Sài Gòn không ạ?',
    );
    cubit.toggleBackgrounds();
    cubit.selectBackground(options.backgrounds.first);
    await _shot(tester, '5_nen_mau');

    await tester.tap(find.text('Mọi người'));
    await _settle(tester, 15);
    await _shot(tester, '6_chon_nguoi_xem');
  });
}
