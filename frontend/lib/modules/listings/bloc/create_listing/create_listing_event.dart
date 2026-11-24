import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/data/models/enums/listing_condition.dart';

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

  /// Hạn mức đã tải trong khoảng này thì dùng luôn, không gọi lại API
  final Duration? maxAge;
  const PostingQuotaRequested({this.done, this.maxAge});
}

class CategorySelected extends CreateListingEvent {
  final String categoryId;

  /// Danh mục con (rỗng khi danh mục chưa chia con)
  final String subcategoryId;
  const CategorySelected(this.categoryId, [this.subcategoryId = '']);
  @override
  List<Object?> get props => [categoryId, subcategoryId];
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

/// Chọn Bán (false) hoặc Cho tặng miễn phí (true)
class FreeChanged extends CreateListingEvent {
  final bool isFree;
  const FreeChanged(this.isFree);
  @override
  List<Object?> get props => [isFree];
}

class PriceChanged extends CreateListingEvent {
  final int? price;
  const PriceChanged(this.price);
  @override
  List<Object?> get props => [price];
}

/// Bật / tắt giá cố định (người mua chỉ đề nghị đúng giá đăng)
class FixedPriceChanged extends CreateListingEvent {
  final bool fixedPrice;
  const FixedPriceChanged(this.fixedPrice);
  @override
  List<Object?> get props => [fixedPrice];
}

/// Có nhiều món giống nhau
class MultipleUnitsChanged extends CreateListingEvent {
  final bool multipleUnits;
  const MultipleUnitsChanged(this.multipleUnits);
  @override
  List<Object?> get props => [multipleUnits];
}

/// Bật / tắt gặp mặt giao dịch
class MeetUpChanged extends CreateListingEvent {
  final bool meetUp;
  const MeetUpChanged(this.meetUp);
  @override
  List<Object?> get props => [meetUp];
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

/// Đổi giá trị một thuộc tính theo danh mục
class AttributeChanged extends CreateListingEvent {
  final String key;
  final String value;
  const AttributeChanged(this.key, this.value);
  @override
  List<Object?> get props => [key, value];
}

/// Bấm "Tiếp" ở bước Thông tin sản phẩm: bật hiển thị lỗi các trường thiếu
class DetailsSubmitted extends CreateListingEvent {
  const DetailsSubmitted();
}

class DraftSaveRequested extends CreateListingEvent {
  const DraftSaveRequested();
}

class PublishRequested extends CreateListingEvent {
  /// Người dùng đã đồng ý trả xu cho tin vượt hạn mức
  final bool payWithCredits;

  /// Vẫn đăng mới dù đã có tin giống vậy đã ẩn / hết hạn
  final bool allowDuplicate;

  /// Vẫn gửi duyệt dù nội dung bị gắn cờ (SĐT, link, hàng cấm)
  final bool acceptFlags;

  const PublishRequested({
    this.payWithCredits = false,
    this.allowDuplicate = false,
    this.acceptFlags = false,
  });

  @override
  List<Object?> get props => [payWithCredits, allowDuplicate, acceptFlags];
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

/// Mở một tin đã đăng để sửa (đang hiển thị, đã ẩn, chờ duyệt, bị từ chối).
/// Tin đã duyệt đang có bản sửa chờ duyệt thì mở bản sửa đó để sửa tiếp.
class ListingEditOpened extends CreateListingEvent {
  final String id;
  const ListingEditOpened(this.id);
  @override
  List<Object?> get props => [id];
}
