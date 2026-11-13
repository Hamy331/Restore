import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/account_listing.dart';
import 'package:restore/modules/account/views/account/account_view.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'support/fake_account_listings_repository.dart';
import 'support/fake_profile_repository.dart';

void main() {
  testWidgets(
    'listing rows show days left, expired listings can be reactivated',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final now = DateTime.now();
      final repository = FakeAccountListingsRepository(
        extra: [
          AccountListing(
            id: '201',
            title: 'Xe đạp địa hình cũ',
            price: 1500000,
            category: 'Xe cộ',
            categoryId: 'vehicles',
            views: 12,
            image: '',
            createdAt: now.subtract(const Duration(days: 40)),
            expiresAt: now.subtract(const Duration(days: 1)),
            status: AccountListingStatus.hidden,
          ),
          AccountListing(
            id: '202',
            title: 'Bàn học gấp gọn',
            price: 300000,
            category: 'Nội thất',
            categoryId: 'furniture',
            views: 3,
            image: '',
            createdAt: now.subtract(const Duration(days: 58)),
            expiresAt: now.add(const Duration(days: 2)),
          ),
        ],
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
      String day(Duration offset) =>
          DateFormat('dd/MM/yyyy').format(now.add(offset));
      final expiresSoon =
          'Hết hạn ${day(const Duration(days: 2))} · còn 2 ngày';
      await tester.scrollUntilVisible(find.text(expiresSoon), 200);
      expect(find.text(expiresSoon), findsOneWidget);

      await tester.scrollUntilVisible(find.text('ĐÃ ẨN (1)'), -200);
      await tester.tap(find.text('ĐÃ ẨN (1)'));
      await tester.pumpAndSettle();
      expect(
        find.text('Đã hết hạn ${day(const Duration(days: -1))}'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('Kích hoạt lại'), 200);
      await tester.tap(find.text('Kích hoạt lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đã kích hoạt lại tin'), findsOneWidget);
      expect(find.text('ĐÃ ẨN (0)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
