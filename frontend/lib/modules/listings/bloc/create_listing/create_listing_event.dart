import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import '../../models/listing_enums.dart';

sealed class CreateListingEvent extends Equatable {
  const CreateListingEvent();
  @override
  List<Object?> get props => [];
}

/// Tải danh sách danh mục (kèm schema thuộc tính) khi mở luồng đăng tin
class CategoriesRequested extends CreateListingEvent {
  const CategoriesRequested();
}

/// Tải hạn mức đăng tin của tài khoản (số tin đã dùng mỗi chuyên mục)
class PostingQuotaRequested extends CreateListingEvent {
  /// Hoàn thành khi tải xong (kể cả lỗi), để màn chọn chuyên mục chờ hạn
  /// mức mới nhất trước khi cho vào trang tạo tin
  final Completer<void>? done;
  const PostingQuotaRequested({this.done});
}

class CategorySelected extends CreateListingEvent {
  final String categoryId;
  const CategorySelected(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class PhotosAdded extends CreateListingEvent {
  final List<String> paths;
  const PhotosAdded(this.paths);
  @override
  List<Object?> get props => [paths];
}

class PhotoRemoved extends CreateListingEvent {
  final int index;
  const PhotoRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class CoverPhotoSet extends CreateListingEvent {
  final int index;
  const CoverPhotoSet(this.index);
  @override
  List<Object?> get props => [index];
}

class DescriptionChanged extends CreateListingEvent {
  final String description;
  const DescriptionChanged(this.description);
  @override
  List<Object?> get props => [description];
}

class TitleChanged extends CreateListingEvent {
  final String title;
  const TitleChanged(this.title);
  @override
  List<Object?> get props => [title];
}

class TradeTypeChanged extends CreateListingEvent {
  final TradeType tradeType;
  const TradeTypeChanged(this.tradeType);
  @override
  List<Object?> get props => [tradeType];
}

class PriceChanged extends CreateListingEvent {
  final int? price;
  const PriceChanged(this.price);
  @override
  List<Object?> get props => [price];
}

/// Giá gốc trước giảm (chỉ gói Cửa hàng), null = không giảm giá
class OriginalPriceChanged extends CreateListingEvent {
  final int? originalPrice;
  const OriginalPriceChanged(this.originalPrice);
  @override
  List<Object?> get props => [originalPrice];
}

class NegotiableChanged extends CreateListingEvent {
  final bool isNegotiable;
  const NegotiableChanged(this.isNegotiable);
  @override
  List<Object?> get props => [isNegotiable];
}

class ExchangeWishChanged extends CreateListingEvent {
  final String exchangeWish;
  const ExchangeWishChanged(this.exchangeWish);
  @override
  List<Object?> get props => [exchangeWish];
}

class AddressChanged extends CreateListingEvent {
  final AddressInfo address;
  const AddressChanged(this.address);
  @override
  List<Object?> get props => [address];
}

class ConditionChanged extends CreateListingEvent {
  final ListingCondition condition;
  const ConditionChanged(this.condition);
  @override
  List<Object?> get props => [condition];
}

/// Chọn thời gian hiển thị: [days] tổng số ngày (null = miễn phí),
/// [startsAt] ngày hẹn bắt đầu (null = ngay khi duyệt)
class DisplayDaysChanged extends CreateListingEvent {
  final int? days;
  final DateTime? startsAt;
  const DisplayDaysChanged({this.days, this.startsAt});
  @override
  List<Object?> get props => [days, startsAt];
}

/// Đổi giá trị một thuộc tính theo danh mục (bước 3)
class AttributeChanged extends CreateListingEvent {
  final String key;
  final String value;
  const AttributeChanged(this.key, this.value);
  @override
  List<Object?> get props => [key, value];
}

/// Bấm "Tiếp tục" ở bước 2: bật hiển thị lỗi cho các trường còn thiếu
class BasicInfoSubmitted extends CreateListingEvent {
  const BasicInfoSubmitted();
}

class DraftSaveRequested extends CreateListingEvent {
  const DraftSaveRequested();
}

class PublishRequested extends CreateListingEvent {
  /// Người dùng đã đồng ý trả xu cho tin vượt hạn mức
  final bool payWithCredits;

  /// Vẫn đăng mới dù đã có tin giống vậy đã ẩn / hết hạn
  final bool allowDuplicate;

  const PublishRequested({
    this.payWithCredits = false,
    this.allowDuplicate = false,
  });

  @override
  List<Object?> get props => [payWithCredits, allowDuplicate];
}

/// Tải danh sách tin nháp; [loadMore] lấy thêm trang sau
class DraftsRequested extends CreateListingEvent {
  final bool loadMore;
  const DraftsRequested({this.loadMore = false});
  @override
  List<Object?> get props => [loadMore];
}

/// Mở một tin nháp để soạn tiếp
class DraftOpened extends CreateListingEvent {
  final String id;
  const DraftOpened(this.id);
  @override
  List<Object?> get props => [id];
}

/// Xóa một tin nháp (kèm ảnh của nó)
class DraftDeleted extends CreateListingEvent {
  final String id;
  const DraftDeleted(this.id);
  @override
  List<Object?> get props => [id];
}
