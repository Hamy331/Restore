import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/views/item_details/widgets/listing_condition_field.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('posting only offers conditions allowed by administrator', (
    tester,
  ) async {
    ListingCondition? selected;
    await tester.pumpWidget(
      _app(
        ListingConditionField(
          selected: null,
          vehicle: false,
          loadActive: () async => {ListingCondition.newItem},
          onSelected: (value) => selected = value,
        ),
      ),
    );
    await tester.tap(find.text('Chọn'));
    await tester.pumpAndSettle();
    expect(find.text('Mới tinh'), findsOneWidget);
    expect(find.text('Như mới'), findsNothing);
    await tester.tap(find.text('Mới tinh'));
    await tester.pumpAndSettle();
    expect(selected, ListingCondition.newItem);
  });

  testWidgets('vehicles use their own condition scale', (tester) async {
    await tester.pumpWidget(
      _app(
        ListingConditionField(
          selected: ListingCondition.likeNew,
          vehicle: true,
          loadActive: () async => ListingCondition.values.toSet(),
          onSelected: (_) {},
        ),
      ),
    );
    expect(find.text('Xe lướt'), findsOneWidget);
    await tester.tap(find.text('Xe lướt'));
    await tester.pumpAndSettle();
    expect(find.text('Hỏng / bán xác'), findsOneWidget);
    expect(find.text('Sử dụng nhiều'), findsNothing);
  });

  test('vehicle scale applies to vehicles except parts', () {
    expect(ListingCondition.usesVehicleScale('vehicles', 'o-to'), isTrue);
    expect(
      ListingCondition.usesVehicleScale('vehicles', 'phu-tung-xe'),
      isFalse,
    );
    expect(ListingCondition.usesVehicleScale('electronics', ''), isFalse);
  });
}
