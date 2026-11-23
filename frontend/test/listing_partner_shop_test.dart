import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/listing_model.dart';

void main() {
  test('partner listings carry the seller shop id', () {
    final partner = ListingModel.fromJson({
      'id': 'l1',
      'title': 'Ghế gỗ',
      'description': '',
      'price': '100000',
      'isPartner': true,
      'shopId': 'shop-1',
    });
    expect([partner.isPartner, partner.shopId], [true, 'shop-1']);

    final personal = ListingModel.fromJson({
      'id': 'l2',
      'title': 'Ghế gỗ',
      'description': '',
      'price': '100000',
      'isPartner': false,
    });
    expect([personal.isPartner, personal.shopId], [false, null]);
  });
}
