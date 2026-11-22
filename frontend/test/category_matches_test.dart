import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/search/utils/category_matches.dart';
import 'package:restore/shared/models/localized_text.dart';

void main() {
  final categories = [
    CategoryModel.fromJson({
      'id': 'vehicles',
      'name': {'vi': 'Xe cộ', 'en': 'Vehicles'},
      'subcategories': [
        {
          'id': 'o-to',
          'name': {'vi': 'Ô tô', 'en': 'Cars'},
        },
        {
          'id': 'xe-may',
          'name': {'vi': 'Xe máy', 'en': 'Motorbikes'},
        },
      ],
    }),
    CategoryModel.fromJson({
      'id': 'furniture',
      'name': {'vi': 'Nội thất, cây cảnh', 'en': 'Furniture'},
      'subcategories': [],
    }),
  ];
  String vi(LocalizedText name) => name.resolve('vi');
  List<String> ids(String query) => [
    for (final match in matchCategories(categories, query, vi))
      match.sub?.id ?? match.parent.id,
  ];

  test('category name typed with or without accents opens the category', () {
    expect(ids('xe cộ'), ['vehicles']);
    expect(ids('xe co'), ['vehicles']);
    expect(ids('o to'), ['o-to']);
    expect(ids('xe'), ['vehicles', 'xe-may']);
  });

  test('short words must match a whole word', () {
    // "co" trùng cả từ "cộ" (bỏ dấu) nên ra Xe cộ, còn "ca" không khớp
    // "cây cảnh" vì chỉ là đầu từ
    expect(ids('co'), ['vehicles']);
    expect(ids('ca'), isEmpty);
    expect(ids('noi that'), ['furniture']);
    expect(ids('noi th'), isEmpty);
    expect(ids(''), isEmpty);
  });
}
