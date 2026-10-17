import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';

/// Một mức giá gợi ý trong sheet Bộ lọc (VD "Dưới 500.000 đ"),
/// mỗi đầu null là không giới hạn
class PriceRangeOption extends Equatable {
  final int? min;
  final int? max;

  const PriceRangeOption({this.min, this.max});

  factory PriceRangeOption.fromJson(Map<String, dynamic> json) =>
      PriceRangeOption(
        min: (json['min'] as num?)?.toInt(),
        max: (json['max'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [min, max];
}

/// Các lựa chọn hiện trong sheet Bộ lọc, nhận từ API
/// `GET /listings/filter-options` để backend thêm danh mục hay đổi mức giá
/// mà không cần cập nhật app. Tình trạng và kiểu giao dịch là enum cố định.
class ListingFilterOptions extends Equatable {
  final List<CategoryModel> categories;
  final List<PriceRangeOption> priceRanges;

  const ListingFilterOptions({
    this.categories = const [],
    this.priceRanges = const [],
  });

  factory ListingFilterOptions.fromJson(Map<String, dynamic> json) =>
      ListingFilterOptions(
        categories: [
          for (final item in json['categories'] as List? ?? const [])
            CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        priceRanges: [
          for (final item in json['priceRanges'] as List? ?? const [])
            PriceRangeOption.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );

  @override
  List<Object?> get props => [categories, priceRanges];
}
