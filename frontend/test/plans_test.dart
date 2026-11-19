import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/plans/repositories/plans_repository.dart';
import 'package:restore/modules/plans/views/plans/plans_view.dart';

void main() {
  testWidgets('buy a plan with points from the plans page', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
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
        builder: (_, _) => MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: PlansView(
            repository: repository,
            categoryRepository: MockCategoryRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('99 xu / 30 ngày'), findsOneWidget);
    expect(find.text('Mua gói'), findsNWidgets(2));

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
    expect(DevPlanOverride.plan.value, SubscriptionPlan.pro);
    expect(find.text('Gia hạn'), findsOneWidget);
    expect(find.text('Nâng cấp'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
