import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/listings/models/posting_quota.dart';
import 'package:restore/modules/listings/widgets/posting_limit_sheet.dart';
import 'package:restore/shared/models/localized_text.dart';

import 'feeds_test.dart' show host;

PostingQuota quota({int wallet = 125, int totalUsed = 1}) =>
    PostingQuota.fromJson({
      'accountType': 'personal',
      'defaultLimit': 2,
      'displayDays': 60,
      'total': {'used': totalUsed, 'limit': 5},
      'wallet': {'available': wallet},
      'categories': [
        {
          'categoryId': 'phones',
          'used': 1,
          'limit': 1,
          'extraCredits': 15,
          'freeAvailable': false,
          'blockedBy': 'CATEGORY',
        },
        {
          'categoryId': 'books',
          'used': 0,
          'limit': 3,
          'extraCredits': 5,
          'freeAvailable': totalUsed < 5,
          'blockedBy': totalUsed < 5 ? null : 'TOTAL',
        },
      ],
    });

const phones = CategoryModel(
  id: 'phones',
  name: LocalizedText({'vi': 'Điện thoại', 'en': 'Phones'}),
  description: LocalizedText({}),
);

void main() {
  test('free slot follows the backend, including the account total', () {
    expect(quota().isFull('phones'), isTrue);
    expect(quota().isFull('books'), isFalse);
    final full = quota(totalUsed: 5);
    expect(full.isFull('books'), isTrue);
    expect(full.forCategory('books').blockedBy, PostingQuotaBlock.total);
    expect(full.forCategory('phones').extraCredits, 15);
    expect(full.minExtraCredits, 5);
    expect(full.walletAvailable, 125);
  });

  Future<PostingLimitAction?> open(
    WidgetTester tester,
    PostingQuota value,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    PostingLimitAction? result;
    await tester.pumpWidget(
      host(
        const Locale('vi'),
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showPostingLimitSheet(
              context,
              category: phones,
              quota: value,
              atPublish: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return result;
  }

  testWidgets('enough points: sheet offers to post for the category price', (
    tester,
  ) async {
    await open(tester, quota());
    expect(find.text('Đăng tin này với 15 xu'), findsOneWidget);
    await tester.tap(find.text('Đăng · 15 xu'));
    await tester.pumpAndSettle();
  });

  testWidgets('not enough points: sheet asks to buy more', (tester) async {
    await open(tester, quota(wallet: 10));
    expect(find.textContaining('Bạn cần nạp thêm 5 xu.'), findsOneWidget);
    expect(find.text('Nạp xu'), findsOneWidget);
    expect(find.text('Đăng · 15 xu'), findsNothing);
  });
}
