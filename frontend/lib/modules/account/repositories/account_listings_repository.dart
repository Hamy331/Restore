import '../../../shared/models/paged_result.dart';
import '../../listings/repositories/listings_repository.dart';
import '../models/account_listing.dart';

/// Hợp đồng tin đăng của tài khoản đang đăng nhập
abstract class AccountListingsRepository {
  Future<PagedResult<AccountListing>> mine(
    AccountListingStatus status, {
    int page = 1,
  });
  Future<void> changeStatus(String id, AccountListingStatus status);
}

/// Bọc `GET /listings/mine` của [ListingsRepository]
class ApiAccountListingsRepository implements AccountListingsRepository {
  ApiAccountListingsRepository([ListingsRepository? repository])
    : _repository = repository ?? ApiListingsRepository();
  final ListingsRepository _repository;

  @override
  Future<PagedResult<AccountListing>> mine(
    AccountListingStatus status, {
    int page = 1,
  }) async {
    final result = await _repository.mine(
      page: page,
      status: status.listingStatus.apiValue,
    );
    return PagedResult(
      page: result.page,
      hasMore: result.hasMore,
      totalItems: result.totalItems,
      items: [
        for (final item in result.items)
          AccountListing(
            id: item.id,
            title: item.title,
            price: item.price ?? 0,
            category: item.categoryName,
            createdAt: item.createdAt,
            views: item.viewCount,
            image: item.coverImage ?? '',
            status: status,
          ),
      ],
    );
  }

  @override
  Future<void> changeStatus(String id, AccountListingStatus status) =>
      _repository.changeStatus(id, status.listingStatus);
}
