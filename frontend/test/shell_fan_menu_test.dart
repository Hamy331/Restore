import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/shell/models/shell_quick_action.dart';
import 'package:restore/modules/shell/widgets/shell_bottom_nav.dart';

void main() {
  Future<void> pumpNav(
    WidgetTester tester, {
    required SubscriptionPlan plan,
    required ValueChanged<int> onSelected,
    required ValueChanged<ShellQuickAction> onAction,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: ShellBottomNav(
            selectedIndex: 0,
            onSelected: onSelected,
            quickActions: ShellQuickAction.forPlan(plan),
            onQuickAction: onAction,
          ),
        ),
      ),
    );
  }

  testWidgets('gói Cá nhân: nút giữa mở thẳng Đăng tin', (tester) async {
    int? selected;
    await pumpNav(
      tester,
      plan: SubscriptionPlan.personal,
      onSelected: (i) => selected = i,
      onAction: (_) => fail('không có menu xoè'),
    );
    await tester.tap(find.bySemanticsLabel('Đăng tin'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(find.text('Poster shop'), findsNothing);
  });

  testWidgets('gói Cửa hàng: xoè menu, chọn Poster shop rồi thu lại', (
    tester,
  ) async {
    ShellQuickAction? picked;
    await pumpNav(
      tester,
      plan: SubscriptionPlan.shop,
      onSelected: (_) {},
      onAction: (a) => picked = a,
    );
    await tester.tap(find.bySemanticsLabel('Mở menu nhanh'));
    await tester.pumpAndSettle();
    expect(find.text('Poster shop'), findsOneWidget);
    expect(find.text('Trang shop'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Poster shop'));
    await tester.pumpAndSettle();
    expect(picked, ShellQuickAction.poster);
    expect(find.text('Poster shop'), findsNothing);
  });

  testWidgets('gói Bán chuyên: bấm nền tối thì đóng menu', (tester) async {
    await pumpNav(
      tester,
      plan: SubscriptionPlan.pro,
      onSelected: (_) {},
      onAction: (_) => fail('không chọn nút nào'),
    );
    await tester.tap(find.bySemanticsLabel('Mở menu nhanh'));
    await tester.pumpAndSettle();
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.text('Poster shop'), findsNothing);

    await tester.tapAt(const Offset(20, 40));
    await tester.pumpAndSettle();
    expect(find.text('Thống kê'), findsNothing);
  });
}
