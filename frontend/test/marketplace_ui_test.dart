import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/chat/views/messages_view.dart';
import 'package:restore/modules/home/views/home_view.dart';
import 'package:restore/modules/listings/presentation/views/create_listing_view.dart';
import 'package:restore/modules/listings/presentation/views/manage_listings_view.dart';
import 'package:restore/modules/listings/data/listing_repository.dart';
import 'package:restore/modules/listings/presentation/bloc/listing_form_cubit.dart';
import 'package:restore/modules/listings/presentation/bloc/manage_listings_cubit.dart';
import 'package:restore/modules/stores/data/store_repository.dart';

class _Categories extends StoreRepository {
  _Categories() : super(dio: Dio());

  @override
  Future<List<StoreCategory>> categories() async => const [
    StoreCategory(id: 'furniture', name: 'Nội thất'),
  ];
}

class _EmptyListings extends ListingRepository {
  _EmptyListings() : super(dio: Dio());

  @override
  Future<ListingPage> list({int page = 1, String query = ''}) async =>
      const ListingPage([], 0, 0);
}

void main() {
  const sizes = <Size>[
    Size(360, 812),
    Size(375, 812),
    Size(412, 915),
    Size(768, 1024),
  ];

  testWidgets('home matches supported mobile and tablet widths', (
    tester,
  ) async {
    for (final size in sizes) {
      await _pumpAt(tester, size, HomeView(repository: _EmptyListings(), storeRepository: _Categories()));
      expect(find.text('Đồ tốt đổi chủ'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'home viewport: $size');
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('messages matches supported mobile and tablet widths', (
    tester,
  ) async {
    for (final size in sizes) {
      await _pumpAt(tester, size, const MessagesView());
      expect(find.text('Tin nhắn'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'messages viewport: $size',
      );
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('selling screens match supported widths', (tester) async {
    for (final size in sizes) {
      await _pumpAt(
        tester,
        size,
        BlocProvider(
          create: (_) => ManageListingsCubit(),
          child: const ManageListingsView(),
        ),
      );
      expect(find.text('Quản lý tin'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'manage viewport: $size');

      await _pumpAt(
        tester,
        size,
        BlocProvider(
          create: (_) => ListingFormCubit(editing: false),
          child: CreateListingView(storeRepository: _Categories()),
        ),
      );
      expect(find.byType(CreateListingView), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'create viewport: $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}
