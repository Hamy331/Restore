import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  testWidgets('Đẩy tin in Manage listings opens the promote page', (
    tester,
  ) async {
    final (_, rowAction, opened) = await _pumpAccount(tester);
    final boost = rowAction('Đẩy tin');
    await tester.scrollUntilVisible(boost, 100);
    await tester.tap(boost);
    await tester.pumpAndSettle();
    expect(opened, ['301']);
    expect(find.text('promote 301'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lên Hot sale in the more menu opens the same page', (
    tester,
  ) async {
    final (_, rowAction, opened) = await _pumpAccount(tester);
    final more = rowAction(null);
    await tester.scrollUntilVisible(more, 100);
    await tester.tap(more);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lên Hot sale'));
    await tester.pumpAndSettle();
    expect(opened, ['301']);
    expect(tester.takeException(), isNull);
  });
}

/// Mở trang Tài khoản với tin '301' đang hiển thị. Trả về repository và hàm
/// tìm nút trong dòng tin đó theo chữ (null = nút ⋯), và các mã tin đã mở
/// trang quảng bá.
Future<(FakeAccountListingsRepository, Finder Function(String?), List<String>)>
_pumpAccount(WidgetTester tester) async {
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

  final opened = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: AccountView(
            profileRepository: FakeProfileRepository(),
            listingsRepository: repository,
          ),
        ),
      ),
      GoRoute(
        path: '/boost/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          opened.add(id);
          return Scaffold(body: Text('promote $id'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => AuthBloc(MockAuthRepository(latency: Duration.zero)),
      child: MaterialApp.router(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
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
  return (repository, rowAction, opened);
}
