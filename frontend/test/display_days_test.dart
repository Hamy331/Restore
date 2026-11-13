import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/bloc/account_listings/account_listings_cubit.dart';
import 'package:restore/modules/listings/models/display_pricing.dart';
import 'package:restore/modules/listings/models/listing_draft.dart';
import 'package:restore/modules/listings/models/posting_quota.dart';
import 'package:restore/modules/listings/widgets/display_days_sheet.dart';
import 'support/fake_account_listings_repository.dart';

const _phones = CategoryPostingQuota(
  categoryId: 'phones',
  used: 0,
  limit: 1,
  displayDays: 30,
  maxDisplayDays: 120,
  dayPackCredits: 15,
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('DisplayPricing (khớp backend display-pricing.ts)', () {
    const personal = DisplayPricing();

    test('giá theo ngày, tròn mốc 30/60/90 thì rẻ hơn', () {
      expect(personal.extraDaysCredits(7, 15), 4);
      expect(personal.extraDaysCredits(30, 15), 14);
      expect(personal.extraDaysCredits(90, 15), 32);
      expect(personal.extraDaysCredits(30, 8), 8);
      expect(personal.extraDaysCredits(1, 3), 1);
      expect(personal.extraDaysCredits(0, 15), 0);
      expect(personal.packSaving(30, 15), 1);
    });

    test('gợi ý mốc khi số ngày lẻ đắt hơn hoặc bằng', () {
      expect(
        personal.suggestedPack(28, 120, 15),
        const SuggestedDayPack(days: 30, credits: 14),
      );
      expect(personal.suggestedPack(30, 120, 15), isNull);
      // Mốc vượt quá tối đa của chuyên mục thì không gợi ý
      expect(personal.suggestedPack(85, 60, 8), isNull);
    });

    test('gói Cửa hàng giảm 30% và đọc từ JSON', () {
      final store = DisplayPricing.fromJson({
        'packs': [
          {'days': 60, 'discountPercent': 20},
          {'days': 30, 'discountPercent': 10},
        ],
        'freeDaysPercent': 200,
        'extendDiscountPercent': 30,
        'autoExtend': true,
      });
      expect(store.packs.first.days, 30);
      expect(store.autoExtend, isTrue);
      expect(store.extraDaysCredits(30, 15), 10);
    });
  });

  test('tin nháp gửi số ngày và ngày bắt đầu (UTC) lên backend', () {
    final start = DateTime.utc(2026, 11, 20, 1);
    final payload = ListingDraft(
      categoryId: 'phones',
      displayDays: 45,
      startsAt: start,
    ).toPayload(category: null);
    expect(payload['displayDays'], 45);
    expect(payload['startsAt'], '2026-11-20T01:00:00.000Z');
    final empty = const ListingDraft().toPayload(category: null);
    expect(empty['displayDays'], isNull);
    expect(empty['startsAt'], isNull);
  });

  testWidgets('gia hạn: chọn +30 ngày thì hiện giá mốc và trả lựa chọn', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 11, 9);
    DisplayDaysChoice? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<DisplayDaysChoice>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: SingleChildScrollView(
                      child: DisplayDaysPicker(
                        mode: DisplayDaysMode.extend,
                        rule: _phones,
                        pricing: const DisplayPricing(),
                        walletAvailable: 50,
                        currentEnd: now.add(const Duration(days: 10)),
                        now: now,
                      ),
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    // Còn 10 ngày, tối đa 120: thêm được 110 nên có đủ các mốc
    expect(find.text('+90 ngày'), findsOneWidget);
    await tester.tap(find.text('+30 ngày'));
    await tester.pump();
    expect(find.text('Gia hạn · 14 xu'), findsOneWidget);
    await tester.tap(find.text('Gia hạn · 14 xu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(result?.days, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gia hạn: đã đủ tối đa thì báo không thêm được', (tester) async {
    final now = DateTime(2026, 11, 11, 9);
    await tester.pumpWidget(
      _app(
        DisplayDaysPicker(
          mode: DisplayDaysMode.extend,
          rule: _phones,
          pricing: const DisplayPricing(),
          walletAvailable: 50,
          currentEnd: now.add(const Duration(days: 120)),
          now: now,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Tin đã hiển thị tối đa 120 ngày, chưa gia hạn thêm được.'),
      findsOneWidget,
    );
  });

  testWidgets('đăng tin: mặc định số ngày miễn phí, không tính xu', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 11, 9);
    await tester.pumpWidget(
      _app(
        DisplayDaysPicker(
          mode: DisplayDaysMode.posting,
          rule: _phones,
          pricing: const DisplayPricing(),
          walletAvailable: 0,
          now: now,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Miễn phí 30 ngày'), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget);
    await tester.tap(find.text('+60 ngày'));
    await tester.pump();
    // 60 ngày thêm của điện thoại: 60 x 15 / 30 x 0,8 = 24 xu
    expect(find.textContaining('24 xu'), findsWidgets);
  });

  test('cubit gửi số ngày gia hạn và công tắc tự gia hạn', () async {
    final repository = FakeAccountListingsRepository();
    final cubit = AccountListingsCubit(repository);
    await cubit.extend('101', 45);
    await cubit.setAutoExtend('101', true);
    expect(repository.extended, [('101', 45)]);
    expect(repository.autoExtended, [('101', true)]);
    await cubit.close();
  });
}
