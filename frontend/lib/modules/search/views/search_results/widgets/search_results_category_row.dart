import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/models/listing_card_item.dart';

/// Hàng danh mục con gợi ý dưới thanh lọc khi chưa lọc danh mục
/// (tìm "iphone" ra "Điện thoại · Phụ kiện · Linh kiện"): lấy từ các tin đã
/// tải, danh mục nhiều tin nhất trước. Bấm là lọc luôn theo danh mục con đó.
class SearchResultsCategoryRow extends StatelessWidget {
  const SearchResultsCategoryRow({
    super.key,
    required this.items,
    required this.categories,
    required this.onSelected,
    this.limit = 6,
  });

  final List<ListingCardItem> items;
  final List<CategoryModel> categories;
  final void Function(String categoryId, String? subcategoryId) onSelected;
  final int limit;

  @override
  Widget build(BuildContext context) {
    // Đếm tin theo (danh mục cha, danh mục con); tin chưa có danh mục con
    // tính vào danh mục cha
    final counts = <(String, String?), int>{};
    for (final item in items) {
      final listing = item.listing;
      final categoryId = listing.categoryId;
      if (categoryId == null) continue;
      final key = (categoryId, listing.subcategoryId);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final byId = {for (final category in categories) category.id: category};
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chips = <Widget>[
      for (final MapEntry(key: (categoryId, subcategoryId)) in entries)
        if (byId[categoryId] case final parent?)
          if ((subcategoryId == null
                  ? parent.name
                  : parent.subcategoryOf(subcategoryId)?.name)
              case final name?)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton(
                onPressed: () => onSelected(categoryId, subcategoryId),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(name.of(context)),
              ),
            ),
    ].take(limit).toList();
    // Một danh mục thì không cần gợi ý
    if (chips.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: chips,
        ),
      ),
    );
  }
}
