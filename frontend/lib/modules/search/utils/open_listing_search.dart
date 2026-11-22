import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:restore/shared/utils/filter_categories.dart';

import '../views/search_results/search_results_view.dart';
import 'category_matches.dart';

/// Đường dẫn cho một lần tìm [query] từ bất kỳ ô tìm kiếm nào của app: gõ
/// đúng tên danh mục ("Sở thích", "điện lạnh", "Ô tô") thì vào trang danh mục
/// đó (đã lọc sẵn, cùng thanh tìm kiếm và thanh lọc như trang kết quả), còn
/// lại là trang kết quả tìm kiếm. [extra] là danh mục để trang mở nhanh.
Future<({String location, Object? extra})> listingSearchDestination(
  BuildContext context,
  String query, {
  bool fromSearch = false,
}) async {
  final categories = await loadFilterCategories();
  final match = context.mounted
      ? exactCategoryMatch(categories, query, (name) => name.of(context))
      : null;
  if (match == null) {
    return (
      location: SearchResultsView.location(query, fromSearch: fromSearch),
      extra: null,
    );
  }
  return (
    location: CategoryDetailView.location(
      match.parent.id,
      subcategoryId: match.sub?.id,
      fromSearch: fromSearch,
    ),
    extra: match.parent,
  );
}

/// Mở trang theo [listingSearchDestination]; [replace] thay trang hiện tại
/// (đang ở trang kết quả mà tìm từ khoá khác). Trả về true khi đã mở trang
/// danh mục (chờ tới khi quay lại nếu không [replace]).
Future<bool> openListingSearch(
  BuildContext context,
  String query, {
  bool replace = false,
  bool fromSearch = false,
}) async {
  final target = await listingSearchDestination(
    context,
    query,
    fromSearch: fromSearch,
  );
  final isCategory = target.extra != null;
  if (!context.mounted) return isCategory;
  if (replace) {
    context.pushReplacement(target.location, extra: target.extra);
  } else {
    await context.push(target.location, extra: target.extra);
  }
  return isCategory;
}
