import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/plans/repositories/plans_repository.dart';
import 'package:restore/modules/plans/views/plans/plans_view.dart';
import 'package:restore/modules/plans/views/plans/widgets/plan_card.dart';

Future<MockPlansRepository> _pumpPlans(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    DevPlanOverride.plan.value = SubscriptionPlan.personal;
  });
  final repository = MockPlansRepository();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp.router(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => PlansView(
                repository: repository,
                categoryRepository: MockCategoryRepository(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('buy a plan with points from the plans page', (tester) async {
    final repository = await _pumpPlans(tester, const Size(400, 1600));
    expect(find.text('Cá nhân'), findsOneWidget);
    expect(find.text('Bán chuyên'), findsOneWidget);
    expect(find.text('Cửa hàng Pro'), findsOneWidget);
    expect(find.text('99'), findsOneWidget);
    expect(find.text('xu / 30 ngày'), findsNWidgets(2));
    expect(find.text('Mua gói'), findsNWidgets(2));

    // Mobile: các gói xếp dọc
    final cards = find.byType(PlanCard);
    expect(
      tester.getTopLeft(cards.at(1)).dy,
      greaterThan(tester.getBottomLeft(cards.at(0)).dy),
    );

    await tester.tap(find.text('Mua gói').first);
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán 99 xu'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownMenuItem<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thanh toán 99 xu'));
    await tester.pumpAndSettle();

    expect((await repository.current()).package.id, 'basic');
    expect(DevPlanOverride.plan.value, SubscriptionPlan.basic);
    expect(find.text('Gia hạn'), findsOneWidget);
    expect(find.text('Nâng cấp'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop shows the three plans side by side', (tester) async {
    await _pumpPlans(tester, const Size(1280, 900));
    final cards = find.byType(PlanCard);
    expect(cards, findsNWidgets(3));
    final first = tester.getRect(cards.at(0));
    final second = tester.getRect(cards.at(1));
    final third = tester.getRect(cards.at(2));
    // Cùng hàng, cùng chiều cao, trái sang phải
    expect(second.top, first.top);
    expect(third.top, first.top);
    expect(second.height, first.height);
    expect(third.height, first.height);
    expect(second.left, greaterThan(first.right));
    expect(third.left, greaterThan(second.right));
    // Nút của 2 gói trả phí thẳng hàng ở đáy thẻ
    final buttons = find.text('Mua gói');
    expect(
      tester.getCenter(buttons.at(0)).dy,
      tester.getCenter(buttons.at(1)).dy,
    );
    expect(tester.takeException(), isNull);
  });
}
