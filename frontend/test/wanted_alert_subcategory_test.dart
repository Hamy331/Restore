import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/wanted_alert/models/wanted_alert_draft.dart';
import 'package:restore/modules/wanted_alert/models/wanted_alert_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

void main() {
  test('alert card names the subcategory after its category', () {
    final item = WantedAlertItem.fromJson({
      'id': 'a',
      'keywords': 'xe',
      'categoryId': 'vehicles',
      'subcategoryId': 'motorbikes',
      'category': {'id': 'vehicles', 'name': 'Xe cộ'},
      'subcategory': {
        'id': 'motorbikes',
        'name': {'vi': 'Xe máy', 'en': 'Motorbikes'},
      },
    });
    expect(item.alert.filter.subcategoryId, 'motorbikes');
    expect(item.categoryName?.resolve('vi'), 'Xe cộ › Xe máy');

    final parentOnly = WantedAlertItem.fromJson({
      'id': 'b',
      'keywords': 'xe',
      'categoryId': 'vehicles',
      'category': {'id': 'vehicles', 'name': 'Xe cộ'},
      'subcategory': null,
    });
    expect(parentOnly.categoryName?.resolve('vi'), 'Xe cộ');
  });

  test('draft sends the subcategory only with a category', () {
    const withCategory = WantedAlertDraft(
      keywords: 'xe máy',
      filter: ListingFilter(categoryId: 'vehicles', subcategoryId: 'motorbikes'),
    );
    expect(withCategory.toJson()['subcategoryId'], 'motorbikes');

    const withoutCategory = WantedAlertDraft(
      keywords: 'xe máy',
      filter: ListingFilter(subcategoryId: 'motorbikes'),
    );
    expect(withoutCategory.toJson()['subcategoryId'], isNull);
  });
}
