import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/listings/models/listing_draft.dart';
import 'package:restore/modules/listings/models/listing_enums.dart';
import 'package:restore/modules/listings/models/posting_quota.dart';
import 'package:restore/modules/listings/utils/listing_validator.dart';

void main() {
  test('chỉ gói Cửa hàng (PRO) được nhập giá gốc', () {
    PostingQuota quota(String tier) => PostingQuota.fromJson({
      'accountType': 'business',
      'defaultLimit': 30,
      'tier': tier,
    });
    expect(quota('PRO').canSetOriginalPrice, isTrue);
    expect(quota('BASIC').canSetOriginalPrice, isFalse);
    expect(quota('PERSONAL').canSetOriginalPrice, isFalse);
  });

  test('giá gốc phải cao hơn giá bán và chỉ gửi khi có bán', () {
    const draft = ListingDraft(price: 2000000, originalPrice: 2000000);
    expect(
      ListingValidator.basicInfoErrors(draft),
      contains(ListingField.originalPrice),
    );
    final ok = draft.copyWith(originalPrice: () => 3000000);
    expect(
      ListingValidator.basicInfoErrors(ok),
      isNot(contains(ListingField.originalPrice)),
    );
    expect(ok.toPayload(category: null)['originalPrice'], '3000000');
    expect(
      ok
          .copyWith(tradeType: TradeType.exchange)
          .toPayload(category: null)['originalPrice'],
      isNull,
    );
    expect(
      ok
          .copyWith(originalPrice: () => null)
          .toPayload(category: null)['originalPrice'],
      isNull,
    );
  });
}
