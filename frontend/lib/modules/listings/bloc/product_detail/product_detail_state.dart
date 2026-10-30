import 'package:equatable/equatable.dart';
import 'package:restore/data/models/listing_model.dart';

import '../../models/product_detail.dart';

enum ProductDetailStatus { loading, ready, failure }

/// Thay đổi phát hiện được khi tự làm mới tin trong lúc đang xem
enum ProductDetailChangeKind {
  /// Tin không còn mua được nữa (đã bán, đã đặt, đã đổi, hết hạn...)
  unavailable,

  /// Tin mở bán trở lại
  available,

  /// Người bán đổi giá
  price,

  /// Người bán sửa nội dung khác (tiêu đề, mô tả, ảnh...)
  info,
}

class ProductDetailChange extends Equatable {
  final ProductDetailChangeKind kind;

  /// Giá trước khi đổi, chỉ có với [ProductDetailChangeKind.price]
  final int? previousPrice;

  const ProductDetailChange(this.kind, {this.previousPrice});

  /// So sánh hai lần tải, null khi người mua không cần biết gì
  static ProductDetailChange? between(
    ProductDetail before,
    ProductDetail after,
  ) {
    final old = before.listing;
    final now = after.listing;
    if (before.isAvailable != after.isAvailable) {
      return ProductDetailChange(
        after.isAvailable
            ? ProductDetailChangeKind.available
            : ProductDetailChangeKind.unavailable,
      );
    }
    if (old.price != now.price || old.isNegotiable != now.isNegotiable) {
      return ProductDetailChange(
        ProductDetailChangeKind.price,
        previousPrice: old.price,
      );
    }
    // Lượt xem tăng liên tục nên không tính là "sửa tin"
    final edited = old.updatedAt != null && now.updatedAt != null
        ? now.updatedAt!.isAfter(old.updatedAt!)
        : old.title != now.title ||
              old.description != now.description ||
              old.images.length != now.images.length;
    return edited
        ? const ProductDetailChange(ProductDetailChangeKind.info)
        : null;
  }

  @override
  List<Object?> get props => [kind, previousPrice];
}

class ProductDetailState extends Equatable {
  final ProductDetailStatus status;
  final ProductDetail? detail;

  /// Tin lấy từ thẻ vừa bấm, hiện ngay ảnh bìa + tiêu đề trong lúc tải
  final ListingModel? preview;

  /// Đang gửi đề nghị giá / yêu cầu mua
  final bool isSubmitting;

  /// Trạng thái "Lưu tin" lúc vừa tải, để biết khi đóng trang có cần báo
  /// trang trước cập nhật thẻ tin hay không
  final bool? initialFavorite;

  /// Thay đổi gần nhất phát hiện khi tự làm mới, kèm số thứ tự để giao diện
  /// báo cho người mua đúng một lần
  final ProductDetailChange? lastChange;
  final int changeCount;

  const ProductDetailState({
    this.status = ProductDetailStatus.loading,
    this.detail,
    this.preview,
    this.isSubmitting = false,
    this.initialFavorite,
    this.lastChange,
    this.changeCount = 0,
  });

  ListingModel? get listing => detail?.listing ?? preview;

  bool get favoriteChanged =>
      detail != null && detail!.isFavorite != initialFavorite;

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductDetail? detail,
    bool? isSubmitting,
    bool? initialFavorite,
    ProductDetailChange? lastChange,
    int? changeCount,
  }) => ProductDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    preview: preview,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    initialFavorite: initialFavorite ?? this.initialFavorite,
    lastChange: lastChange ?? this.lastChange,
    changeCount: changeCount ?? this.changeCount,
  );

  @override
  List<Object?> get props => [
    status,
    detail,
    preview,
    isSubmitting,
    initialFavorite,
    lastChange,
    changeCount,
  ];
}

/// Kết quả gửi đề nghị giá / yêu cầu mua
sealed class ProductActionResult {
  const ProductActionResult();
}

/// Đã gửi, mở cuộc trò chuyện [conversationId] với người bán
class ProductActionSent extends ProductActionResult {
  final String conversationId;

  const ProductActionSent(this.conversationId);
}

/// Không gửi vì tin vừa đổi (đã bán hoặc đổi giá), giao diện đã được báo
/// qua [ProductDetailState.lastChange]
class ProductActionOutdated extends ProductActionResult {
  const ProductActionOutdated();
}

class ProductActionFailed extends ProductActionResult {
  const ProductActionFailed();
}
