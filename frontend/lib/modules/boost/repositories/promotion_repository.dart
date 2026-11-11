import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';

import '../../account/repositories/account_listings_repository.dart';
import '../../listings/models/posting_quota.dart';
import '../../listings/repositories/listings_repository.dart';
import '../../listings/repositories/posting_quota_repository.dart';
import '../models/listing_promotion.dart';
import '../models/promotion_hub.dart';

/// Nguồn dữ liệu trang quảng bá một tin. Lỗi 409 khi đẩy tin / lên Hot sale
/// ném [ListingBoostException] (BOOST_TOO_SOON, FEATURE_ALREADY_ACTIVE,
/// NOT_ENOUGH_CREDITS, LISTING_NOT_BOOSTABLE / LISTING_NOT_FEATURABLE).
abstract class PromotionRepository {
  factory PromotionRepository() => AppEnvironment.useMockData
      ? MockPromotionRepository()
      : ApiPromotionRepository();

  /// Trang Boost: tin đang hiển thị kèm quảng bá đang chạy
  Future<PromotionHub> hub();

  Future<ListingPromotion> overview(String listingId);

  /// Gia hạn tin thêm [days] ngày bằng xu (lỗi ném
  /// `AccountListingActionException`, VD NOT_ENOUGH_CREDITS, EXTEND_TOO_LONG)
  Future<void> extend(String listingId, int days);

  /// Giá gia hạn theo chuyên mục và số xu trong ví (cho sheet gia hạn)
  Future<PostingQuota> postingQuota();

  /// Đẩy tin lên đầu 24 giờ
  Future<BoostResult> boost(String listingId);

  /// Mua gói Hot sale [packageId], trả về hạn kết thúc
  Future<DateTime?> feature(String listingId, String packageId);
}

/// Gọi backend:
/// - `GET /listings/promotions`, `GET /listings/:id/promotion`
/// - `POST /listings/:id/boost`, `POST /listings/:id/feature { packageId }`
/// - `POST /listings/:id/extend { days }`, `GET /listings/posting-quota`
class ApiPromotionRepository implements PromotionRepository {
  ApiPromotionRepository({ApiClient? apiClient, ListingsRepository? listings})
    : _apiClient = apiClient ?? ApiClient(),
      _listings = listings ?? ApiListingsRepository(apiClient: apiClient) {
    _account = ApiAccountListingsRepository(
      _listings,
      ApiPostingQuotaRepository(apiClient: apiClient),
    );
  }

  final ApiClient _apiClient;
  final ListingsRepository _listings;
  late final AccountListingsRepository _account;

  @override
  Future<PromotionHub> hub() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/promotions',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing promotions data');
    return PromotionHub.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> extend(String listingId, int days) =>
      _account.extend(listingId, days);

  @override
  Future<PostingQuota> postingQuota() => _account.postingQuota();

  @override
  Future<ListingPromotion> overview(String listingId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/${Uri.encodeComponent(listingId)}/promotion',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing promotion data');
    return ListingPromotion.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<BoostResult> boost(String listingId) => _listings.boost(listingId);

  @override
  Future<DateTime?> feature(String listingId, String packageId) =>
      _listings.feature(listingId, packageId);
}

/// Dữ liệu mẫu giữ trong bộ nhớ, theo đúng luật của backend: mỗi tin đẩy
/// 1 lần / 24 giờ, một lượt Hot sale chạy tại một thời điểm, thiếu xu thì lỗi
class MockPromotionRepository implements PromotionRepository {
  MockPromotionRepository({
    this.latency = const Duration(milliseconds: 300),
    int available = 40,
    int freeLeft = 1,
  }) : _available = available,
       _freeLeft = freeLeft;

  final Duration latency;
  int _available;
  int _freeLeft;
  static const int _boostCredits = 4;
  static const List<FeatureOption> _options = [
    FeatureOption(packageId: 'featured-1', durationDays: 1, credits: 8),
    FeatureOption(packageId: 'featured-3', durationDays: 3, credits: 23),
    FeatureOption(packageId: 'featured-7', durationDays: 7, credits: 50),
  ];
  final List<PromotionRecord> _history = [];

  /// Tin mẫu của trang Boost; tin 'l1' dùng chung lịch sử với trang chi tiết
  late final List<PromotionHubItem> _items = _seedItems(DateTime.now());

  static List<PromotionHubItem> _seedItems(DateTime now) => [
    PromotionHubItem(
      id: 'l1',
      title: 'iPhone 13 Pro Max 256GB',
      price: 15500000,
      image: 'assets/images/marketplace/detail-macbook.jpg',
      categoryId: 'phones',
      viewCount: 212,
      expiresAt: now.add(const Duration(days: 2, hours: 5)),
      boostCredits: _boostCredits,
    ),
    PromotionHubItem(
      id: 'l2',
      title: 'Xe Honda Vision 2021',
      price: 23000000,
      image: 'assets/images/marketplace/detail-canon.jpg',
      categoryId: 'vehicles',
      viewCount: 87,
      expiresAt: now.add(const Duration(days: 20)),
      boostCredits: 10,
      featuredUntil: now.add(const Duration(days: 2)),
    ),
    PromotionHubItem(
      id: 'l3',
      title: 'Sofa da 3 chỗ',
      price: 4500000,
      image: 'assets/images/marketplace/detail-bookshelf.jpg',
      categoryId: 'furniture',
      viewCount: 34,
      expiresAt: now.add(const Duration(days: 41)),
      boostCredits: 4,
    ),
  ];

  @override
  Future<PromotionHub> hub() async {
    await Future<void>.delayed(latency);
    return PromotionHub(
      available: _available,
      freeLeft: _freeLeft,
      freePerMonth: 1,
      boostsThisMonth: _history
          .where((h) => h.kind == PromotionKind.bump)
          .length,
      featuresThisMonth: _history
          .where((h) => h.kind == PromotionKind.featured)
          .length,
      items: [
        for (final item in _items)
          item.id == 'l1'
              ? PromotionHubItem(
                  id: item.id,
                  title: item.title,
                  price: item.price,
                  image: item.image,
                  categoryId: item.categoryId,
                  viewCount: item.viewCount,
                  expiresAt: item.expiresAt,
                  boostCredits: item.boostCredits,
                  bumpUntil: _running(PromotionKind.bump),
                  featuredUntil: _running(PromotionKind.featured),
                )
              : item,
      ],
    );
  }

  @override
  Future<void> extend(String listingId, int days) async {
    await Future<void>.delayed(latency);
    final index = _items.indexWhere((item) => item.id == listingId);
    if (index < 0) return;
    final item = _items[index];
    _items[index] = PromotionHubItem(
      id: item.id,
      title: item.title,
      price: item.price,
      image: item.image,
      categoryId: item.categoryId,
      viewCount: item.viewCount,
      expiresAt: (item.expiresAt ?? DateTime.now()).add(Duration(days: days)),
      boostCredits: item.boostCredits,
      bumpUntil: item.bumpUntil,
      featuredUntil: item.featuredUntil,
    );
  }

  @override
  Future<PostingQuota> postingQuota() =>
      MockPostingQuotaRepository(latency: latency).getQuota();

  DateTime? _running(PromotionKind kind) {
    final now = DateTime.now();
    for (final item in _history) {
      if (item.kind == kind && item.isRunningAt(now)) return item.endsAt;
    }
    return null;
  }

  @override
  Future<ListingPromotion> overview(String listingId) async {
    await Future<void>.delayed(latency);
    return ListingPromotion(
      listingId: listingId,
      title: 'iPhone 13 Pro Max 256GB',
      price: 15500000,
      image: 'assets/images/marketplace/detail-macbook.jpg',
      promotable: true,
      available: _available,
      boostCredits: _boostCredits,
      boostFreeLeft: _freeLeft,
      boostFreePerMonth: 1,
      boostRunningUntil: _running(PromotionKind.bump),
      featureRunningUntil: _running(PromotionKind.featured),
      featureOptions: _options,
      history: List.unmodifiable(_history),
    );
  }

  @override
  Future<BoostResult> boost(String listingId) async {
    await Future<void>.delayed(latency);
    final running = _running(PromotionKind.bump);
    if (running != null) {
      throw ListingBoostException(
        ListingBoostException.tooSoon,
        details: {'availableAt': running.toUtc().toIso8601String()},
      );
    }
    final free = _freeLeft > 0;
    final credits = free ? 0 : _boostCredits;
    _spend(credits);
    if (free) _freeLeft--;
    _add(PromotionKind.bump, 1, free: free);
    return BoostResult(free: free, credits: credits, freeLeft: _freeLeft);
  }

  @override
  Future<DateTime?> feature(String listingId, String packageId) async {
    await Future<void>.delayed(latency);
    final running = _running(PromotionKind.featured);
    if (running != null) {
      throw ListingBoostException(
        ListingBoostException.featureActive,
        details: {'availableAt': running.toUtc().toIso8601String()},
      );
    }
    final option = _options.firstWhere((o) => o.packageId == packageId);
    _spend(option.credits);
    return _add(PromotionKind.featured, option.durationDays, free: false);
  }

  void _spend(int credits) {
    if (credits > _available) {
      throw ListingBoostException(
        ListingBoostException.notEnoughCredits,
        details: {'missing': credits - _available},
      );
    }
    _available -= credits;
  }

  DateTime _add(PromotionKind kind, int days, {required bool free}) {
    final now = DateTime.now();
    final endsAt = now.add(Duration(days: days));
    _history.insert(
      0,
      PromotionRecord(
        id: '${now.microsecondsSinceEpoch}',
        kind: kind,
        durationDays: days,
        free: free,
        startsAt: now,
        endsAt: endsAt,
      ),
    );
    return endsAt;
  }
}
