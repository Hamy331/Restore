import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/routes/app_router.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/search/views/search_results/search_results_view.dart';
import 'package:restore/shared/widgets/search/app_listing_search_bar.dart';

void main() {
  testWidgets(
    'desktop results reuse the header search across queries and resize',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      final queries = <String>[];
      final interceptor = InterceptorsWrapper(
        onRequest: (request, handler) {
          if (request.path == '/listings/search') {
            queries.add(request.queryParameters['q'] as String);
          }
          handler.resolve(
            Response(
              requestOptions: request,
              data: {'success': true, 'data': <Object>[]},
              statusCode: 200,
            ),
          );
        },
      );
      final interceptors = ApiClient().dio.interceptors;
      interceptors.insert(0, interceptor);
      addTearDown(() => interceptors.remove(interceptor));

      final auth = AuthBloc(MockAuthRepository());
      addTearDown(auth.close);
      auth.add(
        const LoggedIn(
          UserModel(
            id: 'buyer',
            email: 'buyer@example.test',
            fullName: 'Test Buyer',
            username: 'buyer',
          ),
        ),
      );
      await tester.pump();
      final router = createAppRouter(auth);
      addTearDown(router.dispose);
      router.go(SearchResultsView.location('iPhone'));

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

      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, 'iPhone');
      expect(find.byType(AppListingSearchBar), findsNothing);
      final l10n = AppLocalizations.of(tester.element(field))!;
      expect(find.text(l10n.listingFilterButton), findsOneWidget);

      await tester.enterText(field, '  Samsung  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(queries, ['iPhone', 'Samsung']);
      expect(tester.widget<TextField>(field).controller!.text, 'Samsung');
      expect(router.canPop(), isFalse);

      tester.view.physicalSize = const Size(390, 850);
      await tester.pumpAndSettle();
      expect(find.byType(AppListingSearchBar), findsOneWidget);
      expect(find.text('Samsung'), findsOneWidget);
      expect(find.text(l10n.listingFilterButton), findsOneWidget);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      expect(find.byType(AppListingSearchBar), findsNothing);
      expect(tester.widget<TextField>(field).controller!.text, 'Samsung');
    },
  );
}
