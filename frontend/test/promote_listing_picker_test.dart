import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/account_listing.dart';
import 'package:restore/modules/boost/widgets/promote_listing_picker.dart';

import 'support/fake_account_listings_repository.dart';

Future<Future<PromotePick?> Function()> _pump(
  WidgetTester tester,
  FakeAccountListingsRepository repository,
) async {
  late BuildContext host;
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
      home: Builder(
        builder: (context) {
          host = context;
          return const Scaffold();
        },
      ),
    ),
  );
  return () => showPromoteListingPicker(host, repository: repository);
}

void main() {
  testWidgets('Boost in the fan menu lets the seller pick a visible listing', (
    tester,
  ) async {
    final open = await _pump(tester, FakeAccountListingsRepository());
    await tester.pump();
    final result = open();
    await tester.pumpAndSettle();
    expect(find.text('Chọn tin để quảng bá'), findsOneWidget);
    expect(find.text('Tai nghe Sony WH-1000XM4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('promote-pick-102')));
    await tester.pumpAndSettle();
    final pick = await result;
    expect(pick?.listingId, '102');
    expect(tester.takeException(), isNull);
  });

  testWidgets('no visible listing offers to post instead', (tester) async {
    final repository = FakeAccountListingsRepository();
    for (final id in ['101', '102', '103']) {
      await repository.changeStatus(id, AccountListingStatus.hidden);
    }
    final open = await _pump(tester, repository);
    await tester.pump();
    final result = open();
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có tin nào đang hiển thị.'), findsOneWidget);
    await tester.tap(find.text('Đăng tin'));
    await tester.pumpAndSettle();
    final pick = await result;
    expect(pick?.post, isTrue);
    expect(pick?.listingId, isNull);
  });
}
