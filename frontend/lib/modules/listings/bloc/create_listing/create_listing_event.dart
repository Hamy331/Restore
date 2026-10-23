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

class DraftRequested extends CreateListingEvent {
  const DraftRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
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

class SellerTypeChanged extends CreateListingEvent {
  final SellerType sellerType;
  const SellerTypeChanged(this.sellerType);
  @override
  List<Object?> get props => [sellerType];
}

class ConditionChanged extends CreateListingEvent {
  final ListingCondition condition;
  const ConditionChanged(this.condition);
  @override
  List<Object?> get props => [condition];
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
  const PublishRequested();
}
