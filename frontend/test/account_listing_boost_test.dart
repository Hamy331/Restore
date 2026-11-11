import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/account_listing.dart';
import 'package:restore/modules/account/views/account/account_view.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/listings/models/listing_enums.dart';
import 'package:restore/modules/listings/models/posting_quota.dart';
import 'support/fake_account_listings_repository.dart';
import 'support/fake_profile_repository.dart';

void main() {
  testWidgets('boosting a visible listing asks before spending points', (
    tester,
  ) async {
    final (repository, rowAction) = await _pumpAccount(tester);
    final boost = rowAction('Đẩy tin');
    await tester.scrollUntilVisible(boost, 100);
    await tester.tap(boost);
    await tester.pumpAndSettle();
    expect(find.text('Đẩy tin · 6 xu'), findsOneWidget);
    expect(repository.boosted, isEmpty);

    await tester.tap(find.text('Đẩy tin · 6 xu'));
    await tester.pumpAndSettle();
    expect(repository.boosted, ['301']);
    expect(find.text('Đã đẩy tin lên đầu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping boost quickly opens one sheet and sends one request', (
    tester,
  ) async {
    final (repository, rowAction) = await _pumpAccount(tester);
    repository.boostDelay = const Duration(milliseconds: 500);
    final boost = rowAction('Đẩy tin');
    await tester.scrollUntilVisible(boost, 100);
    await tester.tap(boost);
    await tester.tap(boost, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Đẩy tin · 6 xu'), findsOneWidget);

    final pay = find.text('Đẩy tin · 6 xu');
    await tester.tap(pay);
    await tester.tap(pay, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    // Đang gửi yêu cầu: bấm Đẩy tin lần nữa không mở sheet mới
    await tester.tap(boost, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(repository.boosted, ['301']);
    expect(find.text('Đẩy tin · 6 xu'), findsNothing);
    expect(find.text('Tủ gỗ hai cánh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('putting a listing on Hot sale lets the seller pick the days', (
    tester,
  ) async {
    final (repository, rowAction) = await _pumpAccount(tester);
    final more = rowAction(null);
    await tester.scrollUntilVisible(more, 100);
    await tester.tap(more);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lên Hot sale'));
    await tester.pumpAndSettle();
    expect(find.text('1 ngày'), findsOneWidget);
    expect(find.text('Mua · 8 xu'), findsOneWidget);

    await tester.tap(find.text('3 ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mua · 23 xu'));
    await tester.pumpAndSettle();
    expect(repository.featured, [('301', 'featured-3')]);
    expect(find.text('Tin đã lên Hot sale'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Mở trang Tài khoản với tin '301' đang hiển thị. Trả về repository và hàm
/// tìm nút trong dòng tin đó theo chữ (null = nút ⋯).
Future<(FakeAccountListingsRepository, Finder Function(String?))> _pumpAccount(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(360, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final now = DateTime.now();
  final repository =
      FakeAccountListingsRepository(
          extra: [
            AccountListing(
              id: '301',
              title: 'Tủ gỗ hai cánh',
              price: 900000,
              category: 'Nội thất',
              categoryId: 'furniture',
              views: 5,
              image: '',
              createdAt: now.subtract(const Duration(days: 3)),
              expiresAt: now.add(const Duration(days: 57)),
            ),
          ],
        )
        ..quota = const PostingQuota(
          accountType: SellerType.personal,
          defaultLimit: 2,
          displayDays: 60,
          businessLimit: 30,
          walletAvailable: 20,
          categories: {
            'furniture': CategoryPostingQuota(
              categoryId: 'furniture',
              used: 1,
              limit: 2,
              boostCredits: 6,
            ),
          },
        );

  await tester.pumpWidget(
    BlocProvider(
      create: (_) => AuthBloc(MockAuthRepository(latency: Duration.zero)),
      child: MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: AccountView(
            profileRepository: FakeProfileRepository(),
            listingsRepository: repository,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final title = find.text('Tủ gỗ hai cánh');
  await tester.scrollUntilVisible(title, 200);
  final rows = find.ancestor(of: title, matching: find.byType(Column));
  final row = rows.evaluate().firstWhere(
    (element) => find
        .descendant(
          of: find.byElementPredicate((e) => e == element),
          matching: find.text('Đẩy tin'),
        )
        .evaluate()
        .isNotEmpty,
  );
  Finder rowAction(String? label) => find.descendant(
    of: find.byElementPredicate((e) => e == row),
    matching: label == null
        ? find.byType(PopupMenuButton<VoidCallback>)
        : find.text(label),
  );
  return (repository, rowAction);
}
