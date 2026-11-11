import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/category_detail/bloc/category_detail_cubit.dart';
import 'package:restore/modules/category_detail/repositories/category_listings_repository.dart';
import 'package:restore/shared/widgets/listing/app_hot_sale_section.dart';

void main() {
  test('category page loads Hot sale listings of its own category', () async {
    final cubit = CategoryDetailCubit(
      repository: MockCategoryListingsRepository(latency: Duration.zero),
      categoryId: 'electronics',
    );
    await cubit.start();
    final hot = cubit.state.hotItems;
    expect(hot, isNotEmpty);
    expect(hot.every((item) => item.isFeatured), isTrue);
    expect(
      hot.every((item) => item.listing.categoryId == 'electronics'),
      isTrue,
    );
    await cubit.close();
  });

  testWidgets('Hot sale section shows the badge and hides when empty', (
    tester,
  ) async {
    final cubit = CategoryDetailCubit(
      repository: MockCategoryListingsRepository(latency: Duration.zero),
      categoryId: 'electronics',
    );
    await tester.runAsync(cubit.start);
    Widget app(Widget child) => MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );
    final opened = <String>[];
    await tester.pumpWidget(
      app(
        AppHotSaleSection(
          items: cubit.state.hotItems,
          onTap: (item) => opened.add(item.listing.id),
          onFavoriteTap: (_) {},
          // Font thử nghiệm rộng hơn font thật, thẻ 164 sẽ tràn chữ
          cardWidth: 240,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Hot'), findsWidgets);
    await tester.tap(find.text(cubit.state.hotItems.first.listing.title));
    expect(opened, [cubit.state.hotItems.first.listing.id]);

    await tester.pumpWidget(
      app(
        AppHotSaleSection(
          items: const [],
          onTap: (_) {},
          onFavoriteTap: (_) {},
        ),
      ),
    );
    expect(find.byType(ListView), findsNothing);
    await cubit.close();
  });
}
