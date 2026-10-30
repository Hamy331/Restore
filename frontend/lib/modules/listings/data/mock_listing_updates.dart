/// Giả lập thay đổi từ phía người khác trong lúc đang xem tin, chỉ dùng cho
/// dữ liệu mẫu để thấy được trang chi tiết tự cập nhật:
/// - `l7` (Fujifilm X100F): có người mua sau [delay]
/// - `l1` (Canon AE-1): người bán giảm giá 5% sau [delay]
class MockListingUpdates {
  MockListingUpdates._();

  static Duration delay = const Duration(seconds: 20);

  static final Map<String, DateTime> _firstSeen = {};

  /// Trả về JSON đã áp thay đổi giả lập nếu tin đã được xem đủ lâu
  static Map<String, dynamic> apply(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final id = '${json['id']}';
    final time = now ?? DateTime.now();
    final changedAt = _firstSeen.putIfAbsent(id, () => time).add(delay);
    if (time.isBefore(changedAt)) return json;

    return switch (id) {
      'l7' => {...json, 'status': 'SOLD', 'updatedAt': '$changedAt'},
      'l1' => {
        ...json,
        'price': ((json['price'] as num) * 0.95 / 1000).round() * 1000,
        'updatedAt': '$changedAt',
      },
      _ => json,
    };
  }

  static void reset() => _firstSeen.clear();
}
