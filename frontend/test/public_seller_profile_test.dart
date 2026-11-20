import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/views/public_profile/public_profile_view.dart';
import 'package:restore/modules/account/widgets/profile_header.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';

void main() {
  for (final tier in ['PERSONAL', 'BASIC', 'PRO']) {
    testWidgets('public profile renders the $tier seller and switches tabs', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = tier == 'PRO';
      final requests = <RequestOptions>[];
      final fixture = InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final Object data = switch (options.path) {
            '/users/seller' => {
              'id': 'seller',
              'fullName': 'Lan',
              'username': 'lan',
              'avatarUrl': '/api/v1/media/avatars/lan_new.png',
              'createdAt': '2024-01-01',
              'ratingAverage': 4.5,
              'ratingCount': 2,
              'storefront': {
                'tier': tier,
                'listingCount': 1,
                if (shop)
                  'shop': {
                    'id': 'store',
                    'name': 'Lan Store',
                    'verified': true,
                    'logoUrl': '/api/v1/media/shops/lan_logo.png',
                  },
              },
            },
            '/users/seller/reviews' => {
              'items': [],
              'hasMore': false,
              'tags': [],
              'count': 2,
              'sellers': 1,
              'average': 4.5,
            },
            '/feeds' => {
              'items': [
                if (shop)
                  {
                    'id': 'post',
                    'author': {'id': 'seller', 'fullName': 'Lan Store'},
                    'text': 'New stock',
                    'createdAt': '2025-06-01',
                  },
              ],
            },
            '/listings' => [
              {
                'id': 'product',
                'ownerId': 'seller',
                'title': 'Laptop Dell',
                'price': '1000000',
              },
            ],
            _ => <String, dynamic>{},
          };
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'data': data},
            ),
          );
        },
      );
      ApiClient().dio.interceptors.insert(0, fixture);
      addTearDown(() => ApiClient().dio.interceptors.remove(fixture));
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => AuthBloc(ApiAuthRepository()),
          child: MaterialApp(
            locale: Locale(shop ? 'vi' : 'en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const PublicProfileView(userId: 'seller'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(TabBar)))!;
      expect(
        find.widgetWithText(
          Tab,
          shop
              ? l.planShop
              : tier == 'BASIC'
              ? l.planPro
              : l.sellerPersonal,
        ),
        findsOneWidget,
      );
      expect(find.text(shop ? 'Lan Store' : 'Lan'), findsWidgets);
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).url,
        endsWith('/avatars/lan_new.png'),
      );
      expect(
        requests
            .singleWhere((r) => r.path == '/listings')
            .queryParameters['ownerId'],
        'seller',
      );
      expect(
        requests
            .singleWhere((r) => r.path == '/feeds')
            .queryParameters['authorId'],
        'seller',
      );
      expect(find.text('Laptop Dell'), findsOneWidget);
      await tester.tap(find.text(l.feedFollow));
      await tester.pumpAndSettle();
      expect(
        requests.last.path,
        shop ? '/shops/store/follow' : '/users/seller/follow',
      );
      expect(find.text(l.feedUnfollow), findsOneWidget);
      await tester.tap(find.widgetWithText(Tab, l.accActivity));
      await tester.pumpAndSettle();
      expect(find.text(shop ? 'New stock' : l.feedEmpty), findsOneWidget);
      await tester.tap(find.widgetWithText(Tab, l.reviews));
      await tester.pumpAndSettle();
      expect(find.text(l.sellerRatingsTitle), findsOneWidget);
      expect(find.text('4.5'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
