import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/home/repositories/home_repository.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/trusted_shop/repositories/trusted_shop_repository.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import '../support/load_test_fonts.dart';

import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/home/views/home/home_view.dart';
import 'package:restore/modules/trusted_shop/views/trusted_shops/trusted_shops_view.dart';

Widget _app() {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => Scaffold(
          body: HomeView(
            homeRepository: MockHomeRepository(latency: Duration.zero),
            categoryRepository: MockCategoryRepository(latency: Duration.zero),
          ),
        ),
      ),
      GoRoute(
        path: TrustedShopsView.path,
        builder: (_, _) => TrustedShopsView(
          repository: MockTrustedShopRepository(latency: Duration.zero),
        ),
      ),
    ],
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => AuthBloc(MockAuthRepository(latency: Duration.zero)),
      ),
      BlocProvider(
        create: (_) => UserAreaCubit(
          locationRepository: MockLocationRepository(latency: Duration.zero),
        )..selectNationwide(),
      ),
    ],
    child: MaterialApp.router(
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
    ),
  );
}

Future<void> _settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester tester, String file) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final provider = (element.widget as Image).image;
      if (provider is AssetImage ||
          (provider is ResizeImage && provider.imageProvider is AssetImage)) {
        await precacheImage(provider, element);
      }
    }
  });
  await _settle(tester, 5);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() => DevPlanOverride.plan.value = SubscriptionPlan.personal);
  tearDown(() => DevPlanOverride.plan.value = SubscriptionPlan.personal);

  testWidgets('home plan shots', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await _settle(tester, 30);
    await _shot(tester, 'out/home_1_ca_nhan.png');
    DevPlanOverride.next();
    await _settle(tester, 5);
    await _shot(tester, 'out/home_2_ban_chuyen.png');
    DevPlanOverride.next();
    await _settle(tester, 5);
    await _shot(tester, 'out/home_3_cua_hang.png');

    GoRouter.of(
      tester.element(find.byType(HomeView)),
    ).push(TrustedShopsView.path);
    await _settle(tester, 30);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await _settle(tester, 10);
    await _shot(tester, 'out/shop_1.png');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await _settle(tester, 10);
    await _shot(tester, 'out/shop_2.png');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await _settle(tester, 10);
    await _shot(tester, 'out/shop_3.png');
  });
}
