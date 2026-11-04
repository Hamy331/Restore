import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/home/views/home/home_view.dart';
import 'package:restore/modules/trusted_shop/views/trusted_shops/trusted_shops_view.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}


Widget _app() {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: HomeView()),
      ),
      GoRoute(
        path: TrustedShopsView.path,
        builder: (_, _) => const TrustedShopsView(),
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

void main() {
  setUpAll(() async {
    final fonts = '${Platform.environment['FLUTTER_ROOT']}'
        '/bin/cache/artifacts/material_fonts';
    await _loadFont('Roboto', [
      for (final w in ['Regular', 'Medium', 'Bold', 'Black', 'Light', 'Thin'])
        '$fonts/Roboto-$w.ttf',
    ]);
    final lucide =
        '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'lucide_icons_flutter-3.1.25/assets';
    await _loadFont('packages/lucide_icons_flutter/Lucide', [
      '$lucide/lucide.ttf',
    ]);
    for (final w in [100, 200, 300, 400, 500, 600]) {
      await _loadFont('packages/lucide_icons_flutter/Lucide$w', [
        '$lucide/build_font/LucideVariable-w$w.ttf',
      ]);
    }
  });

  testWidgets('home plan shots', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await _settle(tester, 30);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/home_1_ca_nhan.png'),
    );
    DevPlanOverride.next();
    await _settle(tester, 5);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/home_2_ban_chuyen.png'),
    );
    await tester.tap(find.text('TEST'));
    await _settle(tester, 5);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/home_3_cua_hang.png'),
    );

    GoRouter.of(tester.element(find.byType(HomeView))).push(
      TrustedShopsView.path,
    );
    await _settle(tester, 30);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await _settle(tester, 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/shop_1.png'),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await _settle(tester, 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/shop_2.png'),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await _settle(tester, 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/shop_3.png'),
    );
  });
}
