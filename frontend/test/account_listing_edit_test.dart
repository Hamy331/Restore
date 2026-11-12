import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/data/models/listing_revision_model.dart';
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
  testWidgets('rejected edit shows its reason; Chỉnh sửa opens the edit flow', (
    tester,
  ) async {
    final (_, rowAction, opened) = await _pumpEdited(tester);
    expect(find.text('Bản sửa bị từ chối: Ảnh mờ'), findsOneWidget);
    final edit = rowAction('Chỉnh sửa');
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(opened, ['301']);
    expect(find.text('edit 301'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bỏ bản sửa in the more menu discards the edit', (tester) async {
    final (repository, rowAction, _) = await _pumpEdited(tester);
    final more = rowAction(null);
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ bản sửa'));
    await tester.pumpAndSettle();
    expect(repository.discardedEdits, ['301']);
    expect(
      find.text('Đã bỏ bản sửa, tin giữ nguyên bản đang hiển thị'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

/// Mở trang Tài khoản với tin '301' đang hiển thị. Trả về repository và hàm
/// tìm nút trong dòng tin đó theo chữ (null = nút ⋯), và các mã tin đã mở
/// trang quảng bá.
Future<(FakeAccountListingsRepository, Finder Function(String?), List<String>)>
_pumpEdited(WidgetTester tester) async {
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
              editStatus: ListingRevisionStatus.rejected,
              editReason: 'Ảnh mờ',
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
        path: '/create-listing/edit/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          opened.add(id);
          return Scaffold(body: Text('edit $id'));
        },
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
