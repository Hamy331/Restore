import 'package:equatable/equatable.dart';

/// Một trang dữ liệu khi tải danh sách theo lượt (VD 10 tin mỗi lần).
/// API trả về `{ data: [...], meta: { page, hasMore } }`.
class PagedResult<T> extends Equatable {
  final List<T> items;

  /// Trang hiện tại, bắt đầu từ 1
  final int page;
  final bool hasMore;

  const PagedResult({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  const PagedResult.empty() : items = const [], page = 0, hasMore = false;

  /// Thiếu `meta.hasMore` thì coi là còn nếu trang này đầy
  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson, {
    required int page,
    required int pageSize,
  }) {
    final data = json['data'];
    if (data is! List) throw const FormatException('Missing response data');
    final items = [
      for (final item in data)
        itemFromJson(Map<String, dynamic>.from(item as Map)),
    ];
    final meta = json['meta'];
    final pagination = json['pagination'];
    final hasMore = meta is Map && meta['hasMore'] is bool
        ? meta['hasMore'] as bool
        : pagination is Map && pagination['totalPages'] is num
        ? page < (pagination['totalPages'] as num)
        : items.length >= pageSize;
    return PagedResult(items: items, page: page, hasMore: hasMore);
  }

  @override
  List<Object?> get props => [items, page, hasMore];
}
