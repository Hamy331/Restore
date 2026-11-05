import 'package:equatable/equatable.dart';
import '../../../data/models/enums/listing_status.dart';

/// Các tab tin đăng trên trang tài khoản và trạng thái tương ứng ở backend.
enum AccountListingStatus {
  visible(ListingStatus.available),
  pending(ListingStatus.pending),
  hidden(ListingStatus.hidden);

  const AccountListingStatus(this.listingStatus);
  final ListingStatus listingStatus;
}

class AccountListing extends Equatable {
  const AccountListing({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.views,
    required this.image,
    this.createdAt,
    this.status = AccountListingStatus.visible,
  });

  final String id;
  final String title;
  final int price;
  final String category;
  final DateTime? createdAt;
  final int views;
  final String image;
  final AccountListingStatus status;

  AccountListing withStatus(AccountListingStatus value) => AccountListing(
    id: id,
    title: title,
    price: price,
    category: category,
    createdAt: createdAt,
    views: views,
    image: image,
    status: value,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    price,
    category,
    createdAt,
    views,
    image,
    status,
  ];
}
