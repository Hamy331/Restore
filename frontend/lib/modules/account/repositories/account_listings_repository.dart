import 'package:dio/dio.dart';
import '../../../data/models/category_model.dart';
import '../../../shared/models/paged_result.dart';
import '../../listings/models/posting_quota.dart';
import '../../listings/repositories/category_repository.dart';
import '../../listings/repositories/listings_repository.dart';
import '../../listings/repositories/posting_quota_repository.dart';
import '../models/account_listing.dart';

/// Hợp đồng tin đăng của tài khoản đang đăng nhập
abstract class AccountListingsRepository {
  Future<PagedResult<AccountListing>> mine(
    AccountListingStatus status, {
    int page = 1,
  });

  /// Đổi trạng thái tin; hiện lại tin hết hạn mà hết suất thì cần
  /// [payWithCredits]. Backend từ chối thì ném [AccountListingActionException].
  Future<void> changeStatus(
    String id,
    AccountListingStatus status, {
    bool payWithCredits = false,
  });

  /// Gia hạn tin thêm một kỳ bằng xu ([AccountListingActionException] khi lỗi)
  Future<void> extend(String id);

  /// Đẩy tin lên đầu: lượt tặng của gói hoặc trả xu. Lỗi 409 ném
  /// [ListingBoostException].
  Future<BoostResult> boost(String id);

  /// Báo giá và mua tin ưu tiên (Hot sale), xem [ListingsRepository.feature]
  Future<FeatureQuote> featureQuote(String id);
  Future<DateTime?> feature(String id, String packageId);

  /// Hạn mức đăng tin (giá xu, số ngày hiển thị, số xu trong ví)
  Future<PostingQuota> postingQuota();

  /// Danh mục [id] để hiện sheet hết suất, null khi không tìm thấy
  Future<CategoryModel?> category(String id);
}

/// Bọc `GET /listings/mine` của [ListingsRepository]
class ApiAccountListingsRepository implements AccountListingsRepository {
  ApiAccountListingsRepository([
    ListingsRepository? repository,
    PostingQuotaRepository? quotaRepository,
    CategoryRepository? categoryRepository,
  ]) : _repository = repository ?? ApiListingsRepository(),
       _quotaRepository = quotaRepository ?? ApiPostingQuotaRepository(),
       _categoryRepository = categoryRepository ?? ApiCategoryRepository();
  final ListingsRepository _repository;
  final PostingQuotaRepository _quotaRepository;
  final CategoryRepository _categoryRepository;

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
            categoryId: item.categoryId,
            expiresAt: item.expiresAt,
            paidCredits: item.paidCredits,
          ),
      ],
    );
  }

  @override
  Future<void> changeStatus(
    String id,
    AccountListingStatus status, {
    bool payWithCredits = false,
  }) => _conflicts(
    () => _repository.changeStatus(
      id,
      status.listingStatus,
      payWithCredits: payWithCredits,
    ),
  );

  @override
  Future<void> extend(String id) => _conflicts(() => _repository.extend(id));

  @override
  Future<BoostResult> boost(String id) => _repository.boost(id);

  @override
  Future<FeatureQuote> featureQuote(String id) => _repository.featureQuote(id);

  @override
  Future<DateTime?> feature(String id, String packageId) =>
      _repository.feature(id, packageId);

  @override
  Future<PostingQuota> postingQuota() => _quotaRepository.getQuota();

  @override
  Future<CategoryModel?> category(String id) async {
    for (final item in await _categoryRepository.getCategories()) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Đổi lỗi 409 có mã của backend thành [AccountListingActionException]
  Future<void> _conflicts(Future<void> Function() call) async {
    try {
      await call();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (error.response?.statusCode != 409 || data is! Map) rethrow;
      final details = data['details'];
      throw AccountListingActionException(
        '${data['code']}',
        message: data['error'] as String?,
        details: details is Map ? Map<String, dynamic>.from(details) : const {},
      );
    }
  }
}
