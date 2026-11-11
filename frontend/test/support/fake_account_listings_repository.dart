import 'package:restore/modules/account/models/account_listing.dart';
import 'package:restore/modules/account/repositories/account_listings_repository.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/listings/models/listing_enums.dart';
import 'package:restore/modules/listings/models/posting_quota.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';
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

  /// Tin đã được đẩy, theo thứ tự
  final boosted = <String>[];

  @override
  Future<BoostResult> boost(String id) async {
    boosted.add(id);
    if (boostDelay > Duration.zero) await Future<void>.delayed(boostDelay);
    return const BoostResult(free: false, credits: 6, freeLeft: 0);
  }

  /// Độ trễ giả lập của API đẩy tin, để test bấm liên tục
  Duration boostDelay = Duration.zero;

  /// Tin đã mua tin ưu tiên: (id, packageId)
  final featured = <(String, String)>[];

  FeatureQuote featureQuoteResult = const FeatureQuote(
    discountPercent: 0,
    available: 30,
    options: [
      FeatureOption(packageId: 'featured-1', durationDays: 1, credits: 8),
      FeatureOption(packageId: 'featured-3', durationDays: 3, credits: 23),
      FeatureOption(packageId: 'featured-7', durationDays: 7, credits: 50),
    ],
  );

  @override
  Future<FeatureQuote> featureQuote(String id) async => featureQuoteResult;

  @override
  Future<DateTime?> feature(String id, String packageId) async {
    featured.add((id, packageId));
    return DateTime.now().add(const Duration(days: 3));
  }

  /// Hạn mức trả về cho màn quản lý tin (đẩy tin, gia hạn)
  PostingQuota quota = const PostingQuota(
    accountType: SellerType.personal,
    defaultLimit: 2,
    displayDays: 60,
    businessLimit: 30,
  );

  @override
  Future<PostingQuota> postingQuota() async => quota;

  @override
  Future<CategoryModel?> category(String id) async => null;
}
