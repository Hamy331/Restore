import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/insights/models/seller_insights.dart';
import 'package:restore/modules/insights/repositories/insights_repository.dart';
import 'package:restore/modules/insights/views/insights/insights_view.dart';
import 'package:restore/modules/insights/views/insights/widgets/insight_views_chart.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: InsightsView(
        repository: MockInsightsRepository(latency: Duration.zero),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('shows KPIs, chart, top listings and tips; switches range', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.byKey(const ValueKey('ins-kpi-views')), findsOneWidget);
    expect(find.textContaining('Tăng'), findsWidgets);
    expect(find.byKey(const ValueKey('ins-bar-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('ins-bar-7')), findsNothing);
    expect(find.byKey(const ValueKey('ins-top-l1')), findsOneWidget);
    expect(find.byKey(const ValueKey('ins-tip-expiring')), findsOneWidget);
    expect(find.byKey(const ValueKey('ins-tip-boost')), findsOneWidget);

    expect(find.text('Chạm vào cột để xem từng ngày'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ins-bar-0')));
    await tester.pump();
    expect(find.textContaining('lượt xem ·'), findsWidgets);
    expect(find.text('Chạm vào cột để xem từng ngày'), findsNothing);

    await tester.tap(find.text('30 ngày'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('ins-bar-29')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('change vs previous period and nice axis max', () {
    expect(const InsightMetric(120, 100).changePercent, 20);
    expect(const InsightMetric(50, 100).changePercent, -50);
    expect(const InsightMetric(5, 0).changePercent, isNull);
    expect(InsightViewsChart.niceMax(0), 1);
    expect(InsightViewsChart.niceMax(7), 10);
    expect(InsightViewsChart.niceMax(23), 50);
    expect(InsightViewsChart.niceMax(100), 100);
  });

  test('parses GET /listings/insights', () {
    final value = SellerInsights.fromJson({
      'days': 7,
      'totals': {
        'views': 30,
        'viewsPrev': 20,
        'saves': 3,
        'savesPrev': 0,
        'chats': 2,
        'chatsPrev': 4,
      },
      'listings': {
        'active': 3,
        'pending': 1,
        'hidden': 0,
        'sold': 2,
        'expiringSoon': 1,
      },
      'promotions': {'boosts': 2, 'features': 1},
      'daily': [
        {'date': '2026-11-11', 'views': 5, 'saves': 1},
      ],
      'top': [
        {
          'id': 'a',
          'title': 'Tủ',
          'price': '900000',
          'image': null,
          'views': 5,
          'saves': 1,
          'totalViews': 40,
          'bumpUntil': '2030-01-01T00:00:00.000Z',
        },
      ],
    });
    expect(value.views.changePercent, 50);
    expect(value.chats.changePercent, -50);
    expect(value.daily.single.date, DateTime(2026, 11, 11));
    expect(value.top.single.isPromotedAt(DateTime(2026, 11, 11)), isTrue);
    expect([value.sold, value.expiringSoon, value.boosts], [2, 1, 2]);
  });
}
