import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/home/views/home/widgets/home_search_header.dart';
import 'package:restore/modules/home/views/home/widgets/home_top_bar.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';

void main() {
  for (final width in [320.0, 390.0, 600.0]) {
    testWidgets('compact home header stays usable at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);
      var areaTaps = 0;
      var searchTaps = 0;
      var messageTaps = 0;
      var notificationTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeTopBar(
                    areaName: 'Nationwide',
                    onAreaTap: () => areaTaps++,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeSearchHeaderDelegate(
                    hintText: 'Search pre-loved items',
                    onTap: () => searchTaps++,
                    onMessagesTap: () => messageTaps++,
                    onNotificationsTap: () => notificationTaps++,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 1800)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What are you hunting for today?'), findsNothing);
      expect(tester.getSize(find.byType(HomeTopBar)).height, lessThan(70));
      expect(tester.getSize(find.byType(AppSearchPill)).height, 44);
      final surface = tester.widget<AppPinnedHeaderSurface>(
        find.byType(AppPinnedHeaderSurface),
      );
      expect(surface.showDivider, isFalse);

      await tester.tap(find.text('Nationwide'));
      await tester.tap(find.byType(AppSearchPill));
      await tester.tap(find.byIcon(AppIcons.chat));
      await tester.tap(find.byIcon(AppIcons.notification));
      expect([areaTaps, searchTaps, messageTaps, notificationTaps], [1, 1, 1, 1]);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppPinnedHeaderSurface>(
          find.byType(AppPinnedHeaderSurface),
        ).pinned,
        isTrue,
      );
      await tester.tap(find.byType(AppSearchPill));
      await tester.tap(find.byIcon(AppIcons.chat));
      await tester.tap(find.byIcon(AppIcons.notification));
      expect([searchTaps, messageTaps, notificationTaps], [2, 2, 2]);
      expect(tester.takeException(), isNull);
    });
  }
}
