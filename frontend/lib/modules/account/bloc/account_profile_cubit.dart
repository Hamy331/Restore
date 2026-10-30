import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/enums/listing_status.dart';
import '../../listings/repositories/listings_repository.dart';

enum AccountListingStatus { visible, pending, hidden }

class AccountListing {
  const AccountListing({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.posted,
    required this.views,
    required this.image,
    this.status = AccountListingStatus.visible,
  });

  final String id;
  final String title;
  final int price;
  final String category;
  final String posted;
  final int views;
  final String image;
  final AccountListingStatus status;

  AccountListing withStatus(AccountListingStatus value) => AccountListing(
    id: id,
    title: title,
    price: price,
    category: category,
    posted: posted,
    views: views,
    image: image,
    status: value,
  );
}

class AccountProfileState {
  const AccountProfileState({
    required this.listings,
    this.selected = AccountListingStatus.visible,
    this.error,
  });

  final List<AccountListing> listings;
  final AccountListingStatus selected;
  final String? error;

  int count(AccountListingStatus status) =>
      listings.where((listing) => listing.status == status).length;

  List<AccountListing> get displayed =>
      listings.where((listing) => listing.status == selected).toList();
}

/// Dữ liệu mẫu khớp Figma; tách khỏi view để có thể thay bằng API tài khoản.
class AccountProfileCubit extends Cubit<AccountProfileState> {
  AccountProfileCubit({ListingsRepository? repository})
    : _repository = repository,
      super(
        const AccountProfileState(
          listings: [
            AccountListing(
              id: '101',
              title: 'Máy ảnh Fujifilm X-T20 kèm kit',
              price: 7900000,
              category: 'Điện tử',
              posted: '2 ngày trước',
              views: 128,
              image: 'assets/images/marketplace/detail-fujifilm.jpg',
            ),
            AccountListing(
              id: '102',
              title: 'Tai nghe Sony WH-1000XM4',
              price: 3200000,
              category: 'Điện tử',
              posted: '4 ngày trước',
              views: 86,
              image: 'assets/images/marketplace/detail-headphones.jpg',
            ),
            AccountListing(
              id: '103',
              title: 'Kệ sách gỗ thông 4 tầng',
              price: 650000,
              category: 'Nội thất',
              posted: '1 tuần trước',
              views: 41,
              image: 'assets/images/marketplace/detail-bookshelf.jpg',
            ),
          ],
        ),
      ) {
    if (_repository != null) {
      emit(const AccountProfileState(listings: []));
      load();
    }
  }

  final ListingsRepository? _repository;

  Future<void> load() async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final listings = <AccountListing>[];
      var page = 1;
      while (true) {
        final result = await repository.mine(page: page++);
        for (final item in result.items) {
          final status = switch (item.status) {
            ListingStatus.available => AccountListingStatus.visible,
            ListingStatus.pending => AccountListingStatus.pending,
            ListingStatus.hidden => AccountListingStatus.hidden,
            _ => null,
          };
          if (status == null) continue;
          listings.add(AccountListing(
            id: item.id, title: item.title, price: item.price ?? 0,
            category: item.categoryId ?? '',
            posted: item.createdAt?.toLocal().toString().split(' ').first ?? '',
            views: item.viewCount, image: item.coverImage ?? '', status: status,
          ));
        }
        if (!result.hasMore) break;
      }
      if (!isClosed) emit(AccountProfileState(listings: listings, selected: state.selected));
    } catch (_) {
      if (!isClosed) emit(AccountProfileState(listings: state.listings, selected: state.selected, error: 'Không tải được tin đăng.'));
    }
  }

  void select(AccountListingStatus status) =>
      emit(AccountProfileState(listings: state.listings, selected: status));

  Future<void> setStatus(String id, AccountListingStatus status) async {
    if (_repository != null) {
      try {
        await _repository.changeStatus(id, status == AccountListingStatus.hidden ? ListingStatus.hidden : ListingStatus.available);
      } catch (_) {
        if (!isClosed) emit(AccountProfileState(listings: state.listings, selected: state.selected, error: 'Không cập nhật được tin đăng.'));
        return;
      }
    }
    if (isClosed) return;
    emit(
    AccountProfileState(
      selected: state.selected,
      listings: state.listings
          .map((item) => item.id == id ? item.withStatus(status) : item)
          .toList(),
    ),
  );
  }
}
