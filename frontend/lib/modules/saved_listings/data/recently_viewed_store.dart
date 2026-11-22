import 'package:shared_preferences/shared_preferences.dart';

/// Mã các tin vừa mở xem, mới nhất trước, lưu trên máy (trang Xem gần đây).
/// Chỉ giữ mã tin; trang Xem gần đây tải lại dữ liệu mới qua `GET /listings/batch`.
// ponytail: per device, not per account; move to the backend if history must follow the user.
class RecentlyViewedStore {
  RecentlyViewedStore._();

  static const String _key = 'recently_viewed_listing_ids';
  static const int maxItems = 30;

  static Future<List<String>> ids() async =>
      (await SharedPreferences.getInstance()).getStringList(_key) ?? const [];

  /// Đưa [listingId] lên đầu danh sách, giữ tối đa [maxItems] tin
  static Future<void> add(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? const [];
    await prefs.setStringList(
      _key,
      [
        listingId,
        ...current.where((id) => id != listingId),
      ].take(maxItems).toList(),
    );
  }
}
