import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/listing_model.dart';

void main() {
  test('reads a localized category name from the listing detail API', () {
    final listing = ListingModel.fromJson({
      'id': 'l1',
      'title': 'Ấm siêu tốc',
      'status': 'AVAILABLE',
      'category': {
        'id': 'other',
        'name': {'vi': 'Khác', 'en': 'Other'},
      },
    });
    expect(['Khác', 'Other'], contains(listing.categoryName));
  });

  test('still reads a plain category name', () {
    final listing = ListingModel.fromJson({
      'id': 'l1',
      'title': 'Ấm siêu tốc',
      'status': 'AVAILABLE',
      'category': {'id': 'other', 'name': 'Khác'},
    });
    expect(listing.categoryName, 'Khác');
  });
}
