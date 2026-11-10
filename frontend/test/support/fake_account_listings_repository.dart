import 'package:restore/modules/account/models/account_listing.dart';
import 'package:restore/modules/account/repositories/account_listings_repository.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/listings/models/listing_enums.dart';
import 'package:restore/modules/listings/models/posting_quota.dart';
import 'package:restore/shared/models/paged_result.dart';

/// Ba tin đăng trong bộ nhớ cho test tab tin đăng.
class FakeAccountListingsRepository implements AccountListingsRepository {
  FakeAccountListingsRepository({List<AccountListing> extra = const []}) {
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
      ...extra,
    ];
  }

  late List<AccountListing> _items;

  /// Lần đổi trạng thái gần nhất có kèm trả xu không
  bool lastPayWithCredits = false;

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
  Future<void> changeStatus(
    String id,
    AccountListingStatus status, {
    bool payWithCredits = false,
  }) async {
    lastPayWithCredits = payWithCredits;
    _items = [
      for (final item in _items) item.id == id ? item.withStatus(status) : item,
    ];
  }

  @override
  Future<void> extend(String id) async {}

  @override
  Future<PostingQuota> postingQuota() async => const PostingQuota(
    accountType: SellerType.personal,
    defaultLimit: 2,
    displayDays: 60,
    businessLimit: 30,
  );

  @override
  Future<CategoryModel?> category(String id) async => null;
}
