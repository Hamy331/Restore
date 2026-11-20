import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/bloc/product_detail/product_detail_cubit.dart';
import 'package:restore/modules/listings/models/product_detail.dart';
import 'package:restore/modules/listings/repositories/product_detail_repository.dart';
import 'package:restore/modules/listings/views/product_detail/product_detail_desktop_view.dart';

/// Chi tiết tin chỉ trả về khi test cho phép
class _SlowRepository implements ProductDetailRepository {
  final detail = Completer<ProductDetail>();

  @override
  Future<ProductDetail> getDetail(String listingId) => detail.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'desktop places offers above the shop and reveals the phone in place',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final interceptors = ApiClient().dio.interceptors;
      final profile = InterceptorsWrapper(
        onRequest: (request, handler) => handler.resolve(
          Response(
            requestOptions: request,
            statusCode: 200,
            data: {
              'data': {'id': 'seller', 'fullName': 'Camera Shop'},
            },
          ),
        ),
      );
      interceptors.insert(0, profile);
      addTearDown(() => interceptors.remove(profile));

      final repository = _SlowRepository();
      final cubit = ProductDetailCubit(listingId: 'l1', repository: repository);
      addTearDown(cubit.close);
      repository.detail.complete(
        const ProductDetail(
          listing: ListingModel(
            id: 'l1',
            ownerId: 'seller',
            title: 'Film camera',
            description: 'Sample description',
            price: 1500000,
            isPartner: true,
          ),
          seller: UserModel(
            id: 'seller',
            email: '',
            fullName: 'Camera Shop',
            username: 'camera-shop',
            phone: '0912 345 678',
          ),
          areaLabel: '',
        ),
      );
      cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const ProductDetailDesktopView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phone = find.text('Show phone number');
      final offer = find.text('Negotiate price');
      final seller = find.text('Camera Shop');
      expect(
        tester.getTopLeft(phone).dy,
        lessThan(tester.getTopLeft(offer).dy),
      );
      expect(
        tester.getTopLeft(offer).dy,
        lessThan(tester.getTopLeft(seller).dy),
      );
      expect(find.text('Write a message…'), findsOneWidget);
      expect(find.text('Quick chat'), findsOneWidget);
      expect(find.text('ReStore partner'), findsOneWidget);
      expect(find.text('0912 345 678'), findsNothing);
      await tester.tap(phone);
      await tester.pumpAndSettle();
      expect(find.text('0912 345 678'), findsOneWidget);
      expect(phone, findsNothing);
      expect(tester.takeException(), isNull);
      cubit.pauseLiveUpdates();
    },
  );

  test('leaving the page before the listing loads does not throw', () async {
    final repository = _SlowRepository();
    final cubit = ProductDetailCubit(listingId: 'l1', repository: repository);
    final loading = cubit.load();
    await cubit.close();
    repository.detail.completeError(Exception('network'));
    await expectLater(loading, completes);
  });
}
