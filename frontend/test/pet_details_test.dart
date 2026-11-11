import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/data/listing_mock_data.dart';
import 'package:restore/modules/listings/models/listing_draft.dart';
import 'package:restore/modules/listings/utils/attribute_value_formatter.dart';
import 'package:restore/modules/listings/utils/listing_validator.dart';
import 'package:restore/modules/listings/views/listing_details/widgets/listing_attribute_field.dart';

CategoryModel _category(String id) => CategoryModel.fromJson(
  ListingMockData.categories.firstWhere((item) => item['id'] == id),
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  final pets = _category('pets');
  final phones = _category('phone');
  final age = pets.attributes.firstWhere((item) => item.key == 'age_months');

  test('pets do not ask for item condition, phones still do', () {
    expect(pets.hasCondition, isFalse);
    expect(phones.hasCondition, isTrue);
    const draft = ListingDraft();
    expect(
      ListingValidator.detailErrors(draft, pets),
      isNot(contains(ListingValidator.conditionKey)),
    );
    expect(
      ListingValidator.detailErrors(draft, phones),
      contains(ListingValidator.conditionKey),
    );
    // Đổi từ danh mục khác sang thú cưng: tình trạng cũ không gửi lên
    final payload = const ListingDraft(
      condition: ListingCondition.likeNew,
    ).toPayload(category: pets);
    expect(payload['condition'], isNull);
  });

  test('age picks the shortest unit to show', () {
    expect(age.bestUnitFor(24)?.value, 'year');
    expect(age.bestUnitFor(18)?.value, 'month');
    expect(age.bestUnitFor(null)?.value, 'month');
  });

  testWidgets('age can be typed in years and is stored in months', (
    tester,
  ) async {
    String? sent;
    await tester.pumpWidget(
      _app(
        ListingAttributeField(
          attribute: age,
          value: null,
          onChanged: (value) => sent = value,
        ),
      ),
    );
    await tester.tap(find.text('năm'));
    await tester.enterText(find.byType(TextField), '2');
    expect(sent, '24');
    await tester.tap(find.text('tháng'));
    expect(sent, '2');
  });

  testWidgets('saved age opens in years and reads "3 năm"', (tester) async {
    late String? shown;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            shown = AttributeValueFormatter.format(context, age, '36');
            return ListingAttributeField(
              attribute: age,
              value: '36',
              onChanged: (_) {},
            );
          },
        ),
      ),
    );
    expect(shown, '3 năm');
    expect(find.widgetWithText(TextField, '3'), findsOneWidget);
  });
}
