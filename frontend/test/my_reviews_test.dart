import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/routes/app_router.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/views/my_reviews/my_reviews_view.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';

void main() {
  testWidgets(
    'reviewing a trade and viewing received ratings works across sizes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 760);
      addTearDown(tester.view.reset);

      const user = UserModel(
        id: 'buyer',
        email: 'buyer@example.test',
        fullName: 'Test Buyer',
        username: 'buyer',
      );
      const trade = {
        'conversationId': 'listing-context',
        'title': 'Film camera',
        'price': '1500000',
        'isSeller': false,
        'recipientName': 'Camera Shop',
        'confirmedAt': '2026-11-18T08:00:00Z',
      };
      Map<String, dynamic>? submitted;
      final interceptor = InterceptorsWrapper(
        onRequest: (request, handler) {
          final sent = submitted;
          final data = switch (request.path) {
            '/conversations/events' => ResponseBody.fromString('', 200),
            '/users/me/reviews' => {
              'items': [
                if (request.queryParameters['status'] == 'pending' &&
                    sent == null)
                  trade,
                if (request.queryParameters['status'] == 'submitted' &&
                    sent != null)
                  {...trade, 'review': sent},
              ],
              'hasMore': false,
            },
            '/users/buyer/reviews' => {
              'items': [
                {
                  'author': {'fullName': 'Camera Shop'},
                  'trade': trade,
                  'stars': 5,
                  'comment': 'Buyer was punctual',
                  'tags': [],
                  'createdAt': '2026-11-19T08:00:00Z',
                },
              ],
              'tags': [],
              'count': 1,
              'sellers': 1,
              'average': 5,
              'hasMore': false,
            },
            '/users/me' => user.toJson(),
            '/conversations/unread-count' => {'count': 0},
            _ => <String, dynamic>{},
          };
          if (request.path == '/conversations/listing-context/review' &&
              request.method == 'POST') {
            submitted = {
              ...(request.data as Map<String, dynamic>),
              'createdAt': '2026-11-19T08:00:00Z',
            };
          }
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: data is ResponseBody ? data : {'data': data},
            ),
          );
        },
      );
      final interceptors = ApiClient().dio.interceptors;
      interceptors.insert(0, interceptor);
      addTearDown(() => interceptors.remove(interceptor));

      final auth = AuthBloc(MockAuthRepository())..add(const LoggedIn(user));
      addTearDown(auth.close);
      await tester.pump();
      final router = createAppRouter(auth)..go(MyReviewsView.path);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: auth),
            BlocProvider(
              create: (_) =>
                  UserAreaCubit(locationRepository: MockLocationRepository())
                    ..selectNationwide(),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rate seller'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('5 / 5'));
      await tester.enterText(find.byType(TextField), 'Camera as described');
      await tester.tap(find.text('Submit review'));
      await tester.pumpAndSettle();
      expect(submitted?['stars'], 5);
      expect(find.text('Film camera'), findsNothing);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submitted'));
      await tester.pumpAndSettle();
      expect(find.text('Camera as described'), findsOneWidget);

      await tester.tap(find.text('Ratings'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        MyReviewsView.ratingsPath,
      );
      expect(find.text('Buyer was punctual'), findsOneWidget);
      expect(find.text('Camera as described'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
