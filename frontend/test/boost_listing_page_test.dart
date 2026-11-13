import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/boost/models/listing_promotion.dart';
import 'package:restore/modules/boost/repositories/promotion_repository.dart';
import 'package:restore/modules/boost/views/boost_listing/boost_listing_view.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';

/// Đếm số lần gọi và cho chờ khi đẩy tin, để thử bấm liên tục
class _CountingRepository extends MockPromotionRepository {
  _CountingRepository({super.freeLeft, this.visible = true})
    : super(latency: Duration.zero);

  final bool visible;
  int boosts = 0;
  final List<String> features = [];
  Duration boostDelay = Duration.zero;

  @override
  Future<ListingPromotion> overview(String listingId) async {
    final value = await super.overview(listingId);
    if (visible) return value;
    return ListingPromotion(
      listingId: value.listingId,
      title: value.title,
      promotable: false,
      available: value.available,
      boostCredits: value.boostCredits,
    );
  }

  @override
  Future<BoostResult> boost(String listingId) async {
    boosts++;
    await Future<void>.delayed(boostDelay);
    return super.boost(listingId);
  }

  @override
  Future<DateTime?> feature(String listingId, String packageId) {
    features.add(packageId);
    return super.feature(listingId, packageId);
  }
}

Future<void> _pump(WidgetTester tester, PromotionRepository repository) async {
  tester.view.physicalSize = const Size(400, 1400);
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
      home: BoostListingView(listingId: 'l1', repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('free boost asks first, then shows running state and history', (
    tester,
  ) async {
    final repository = _CountingRepository();
    await _pump(tester, repository);
    expect(find.text('Quảng bá tin'), findsOneWidget);
    expect(find.text('Ví của bạn: 40 xu'), findsOneWidget);
    expect(find.text('Tin này chưa được quảng bá lần nào.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('promo-boost-button')));
    await tester.pumpAndSettle();
    expect(repository.boosts, 0, reason: 'phải hỏi lại trước');
    await tester.tap(find.byKey(const ValueKey('promo-confirm')));
    await tester.pumpAndSettle();

    expect(repository.boosts, 1);
    expect(find.text('Đã đẩy tin lên đầu'), findsOneWidget);
    expect(find.textContaining('Đẩy lại sau'), findsOneWidget);
    expect(find.byKey(const ValueKey('promo-chip-boost')), findsOneWidget);
    expect(find.text('Đẩy tin 24 giờ'), findsNWidgets(2));
    expect(find.text('Lượt tặng'), findsOneWidget);
    expect(find.text('Ví của bạn: 40 xu'), findsOneWidget);

    // Đang chạy: nút bị khoá
    await tester.tap(find.byKey(const ValueKey('promo-boost-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('promo-confirm')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hot sale: pick 3 days, pay points, then locked while running', (
    tester,
  ) async {
    final repository = _CountingRepository();
    await _pump(tester, repository);
    await tester.tap(find.byKey(const ValueKey('promo-option-featured-3')));
    await tester.pumpAndSettle();
    expect(find.text('Mua · 23 xu'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('promo-feature-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ví còn 17 xu sau khi trả.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('promo-confirm')));
    await tester.pumpAndSettle();

    expect(repository.features, ['featured-3']);
    expect(find.text('Tin đã lên Hot sale'), findsOneWidget);
    expect(find.text('Ví của bạn: 17 xu'), findsOneWidget);
    expect(find.text('Hot sale 3 ngày'), findsOneWidget);
    expect(find.text('Đang chạy'), findsWidgets);
    expect(find.byKey(const ValueKey('promo-chip-hot')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paid boost: tapping confirm twice sends one request', (
    tester,
  ) async {
    final repository = _CountingRepository(freeLeft: 0)
      ..boostDelay = const Duration(milliseconds: 300);
    await _pump(tester, repository);
    expect(find.text('Đẩy tin · 4 xu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('promo-boost-button')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('promo-confirm'));
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(
      find.byKey(const ValueKey('promo-boost-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(repository.boosts, 1);
    expect(find.text('Ví của bạn: 36 xu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden listing shows a notice instead of the offers', (
    tester,
  ) async {
    await _pump(tester, _CountingRepository(visible: false));
    expect(find.byKey(const ValueKey('boost-not-promotable')), findsOneWidget);
    expect(find.byKey(const ValueKey('promo-boost-card')), findsNothing);
    expect(find.byKey(const ValueKey('promo-feature-card')), findsNothing);
  });

  test('parses the promotion API response', () {
    final value = ListingPromotion.fromJson({
      'listingId': 'a',
      'title': 'Tủ',
      'price': '900000',
      'image': null,
      'status': 'AVAILABLE',
      'promotable': true,
      'available': 11,
      'discountPercent': 20,
      'boost': {
        'credits': 4,
        'free': false,
        'freeLeft': 0,
        'freePerMonth': 5,
        'runningUntil': '2026-11-12T09:00:00.000Z',
      },
      'feature': {
        'runningUntil': null,
        'options': [
          {'packageId': 'featured-1', 'durationDays': 1, 'credits': 8},
        ],
      },
      'history': [
        {
          'id': 'p1',
          'kind': 'BUMP',
          'packageId': 'bump-1',
          'durationDays': 1,
          'source': 'INCLUDED',
          'startsAt': '2026-11-11T09:00:00.000Z',
          'endsAt': '2026-11-12T09:00:00.000Z',
        },
      ],
    });
    expect(value.price, 900000);
    expect(value.boostCost, 4);
    expect(value.boostRunningUntil, isNotNull);
    expect(value.featureRunningUntil, isNull);
    expect(value.featureOptions.single.credits, 8);
    expect(value.history.single.kind, PromotionKind.bump);
    expect(value.history.single.free, isTrue);
  });
}
