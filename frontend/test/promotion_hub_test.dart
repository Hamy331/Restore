import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/boost/bloc/promotion_hub_cubit.dart';
import 'package:restore/modules/boost/models/promotion_hub.dart';
import 'package:restore/modules/boost/repositories/promotion_repository.dart';
import 'package:restore/modules/boost/views/promotion_hub/promotion_hub_view.dart';

Future<void> _pump(WidgetTester tester, PromotionRepository repository) async {
  tester.view.physicalSize = const Size(400, 1600);
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
      home: PromotionHubView(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Boost page groups listings and boosts from the list', (
    tester,
  ) async {
    await _pump(tester, MockPromotionRepository(latency: Duration.zero));
    expect(find.text('Quảng bá'), findsOneWidget);
    expect(find.text('Ví của bạn: 40 xu'), findsOneWidget);
    expect(find.text('Đẩy miễn phí còn 1/1 lượt'), findsOneWidget);
    expect(find.text('Tất cả · 3'), findsOneWidget);
    expect(find.text('Đang quảng bá · 1'), findsOneWidget);
    expect(find.text('Sắp hết hạn · 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-chip-hot')), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-extend-l1')), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-extend-l3')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hub-expiring-banner')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hub-item-l1')), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-item-l3')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hub-boost-l1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('promo-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Đã đẩy tin lên đầu'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-chip-boost')), findsOneWidget);
    expect(
      find.text('Tháng này: 1 lượt đẩy · 0 lượt Hot sale'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hub-filter-running')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hub-item-l1')), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-item-l2')), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-item-l3')), findsNothing);
    // Hết lượt tặng: tin khác hiện giá xu
    await tester.ensureVisible(find.byKey(const ValueKey('hub-filter-idle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hub-filter-idle')));
    await tester.pumpAndSettle();
    expect(find.text('Đẩy tin · 4 xu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('filters by running, expiring and idle', () {
    final now = DateTime(2026, 11, 11, 12);
    final state = PromotionHubState(
      status: PromotionHubStatus.ready,
      hub: PromotionHub(
        available: 0,
        items: [
          PromotionHubItem(
            id: 'a',
            title: 'A',
            bumpUntil: now.add(const Duration(hours: 3)),
            expiresAt: now.add(const Duration(days: 30)),
          ),
          PromotionHubItem(
            id: 'b',
            title: 'B',
            expiresAt: now.add(const Duration(days: 3)),
          ),
          PromotionHubItem(
            id: 'c',
            title: 'C',
            expiresAt: now.add(const Duration(days: 3)),
            autoExtend: true,
            featuredUntil: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );
    List<String> ids(PromotionHubFilter f) =>
        state.itemsAt(now, f).map((i) => i.id).toList();
    expect(ids(PromotionHubFilter.running), ['a']);
    expect(ids(PromotionHubFilter.expiring), ['b']);
    expect(ids(PromotionHubFilter.idle), ['b', 'c']);
  });

  test('parses GET /listings/promotions', () {
    final hub = PromotionHub.fromJson({
      'available': 11,
      'discountPercent': 20,
      'boost': {'freeLeft': 2, 'freePerMonth': 5},
      'thisMonth': {'boosts': 3, 'features': 1},
      'items': [
        {
          'id': 'x',
          'title': 'Tủ',
          'price': '900000',
          'image': null,
          'categoryId': 'furniture',
          'viewCount': 5,
          'expiresAt': '2026-11-20T00:00:00.000Z',
          'autoExtend': false,
          'boostCredits': 4,
          'bumpUntil': null,
          'featuredUntil': '2026-11-13T00:00:00.000Z',
        },
      ],
    });
    expect(
      [hub.freeLeft, hub.boostsThisMonth, hub.featuresThisMonth],
      [2, 3, 1],
    );
    expect(hub.items.single.price, 900000);
    expect(hub.boostCostOf(hub.items.single), 0);
    expect(hub.items.single.featuredUntil, isNotNull);
  });
}
