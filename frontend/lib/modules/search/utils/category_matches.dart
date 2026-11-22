import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/models/localized_text.dart';

/// Một danh mục khớp từ khoá: danh mục cha, hoặc danh mục con [sub] của nó
typedef CategoryMatch = ({CategoryModel parent, SubcategoryModel? sub});

/// Danh mục / danh mục con có tên khớp từ khoá đang gõ, VD gợi ý
/// "Xe cộ" khi gõ "xe cộ". Mỗi từ gõ phải khớp đầu một từ trong tên (không
/// dấu); từ dưới 3 ký tự phải trùng cả từ để "co" không ra "Cây cảnh".
/// [label] lấy tên theo ngôn ngữ đang dùng.
List<CategoryMatch> matchCategories(
  List<CategoryModel> categories,
  String query,
  String Function(LocalizedText name) label, {
  int limit = 3,
}) {
  final words = _words(query);
  if (words.isEmpty) return const [];
  bool hits(LocalizedText name) {
    final tokens = _words(label(name));
    return words.every(
      (word) => tokens.any(
        (token) => word.length < 3 ? token == word : token.startsWith(word),
      ),
    );
  }

  return [
    for (final parent in categories) ...[
      if (hits(parent.name)) (parent: parent, sub: null),
      for (final sub in parent.subcategories)
        if (hits(sub.name)) (parent: parent, sub: sub),
    ],
  ].take(limit).toList();
}

List<String> _words(String text) => VietnameseText.normalize(text)
    .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
    .where((w) => w.isNotEmpty)
    .toList();

/// Từ khoá trùng đúng tên một danh mục / danh mục con (không phân biệt hoa
/// thường, có dấu hay không dấu), VD "sở thích", "dien lanh", "Ô tô". Danh mục
/// cha được ưu tiên khi trùng tên với danh mục con của nó.
CategoryMatch? exactCategoryMatch(
  List<CategoryModel> categories,
  String query,
  String Function(LocalizedText name) label,
) {
  final key = _words(query).join(' ');
  if (key.isEmpty) return null;
  bool same(LocalizedText name) => _words(label(name)).join(' ') == key;
  for (final parent in categories) {
    if (same(parent.name)) return (parent: parent, sub: null);
  }
  for (final parent in categories) {
    for (final sub in parent.subcategories) {
      if (same(sub.name)) return (parent: parent, sub: sub);
    }
  }
  return null;
}
