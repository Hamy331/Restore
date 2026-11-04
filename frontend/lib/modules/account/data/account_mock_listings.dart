import '../../../shared/models/paged_result.dart';
import '../bloc/account_profile_cubit.dart';

/// Tin đăng mẫu khớp Figma, dùng khi bật `AppEnvironment.useMockData`.
class MockAccountListingsSource implements AccountListingsSource {
  MockAccountListingsSource() {
    final now = DateTime.now();
    _items = [
      AccountListing(
        id: '101',
        title: 'Máy ảnh Fujifilm X-T20 kèm kit',
        price: 7900000,
        category: 'Điện tử',
        createdAt: now.subtract(const Duration(days: 2)),
        views: 128,
        image: 'assets/images/marketplace/detail-fujifilm.jpg',
      ),
      AccountListing(
        id: '102',
        title: 'Tai nghe Sony WH-1000XM4',
        price: 3200000,
        category: 'Điện tử',
        createdAt: now.subtract(const Duration(days: 4)),
        views: 86,
        image: 'assets/images/marketplace/detail-headphones.jpg',
      ),
      AccountListing(
        id: '103',
        title: 'Kệ sách gỗ thông 4 tầng',
        price: 650000,
        category: 'Nội thất',
        createdAt: now.subtract(const Duration(days: 7)),
        views: 41,
        image: 'assets/images/marketplace/detail-bookshelf.jpg',
      ),
    ];
  }

  late List<AccountListing> _items;

  @override
  Future<PagedResult<AccountListing>> mine(
    AccountListingStatus status, {
    int page = 1,
  }) async {
    final rows = _items.where((item) => item.status == status).toList();
    return PagedResult(
      items: rows.skip((page - 1) * 20).take(20).toList(),
      page: page,
      hasMore: page * 20 < rows.length,
      totalItems: rows.length,
    );
  }

  @override
  Future<void> changeStatus(String id, AccountListingStatus status) async {
    _items = [
      for (final item in _items) item.id == id ? item.withStatus(status) : item,
    ];
  }
}
