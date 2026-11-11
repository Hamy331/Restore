import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/shared/models/geo_point.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/shared/models/paged_result.dart';
import 'package:dio/dio.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/category_model.dart';
import '../data/mock_posting_quota_store.dart';
import '../models/draft_quota.dart';
import '../models/listing_draft.dart';
import '../models/posting_quota.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/data/models/listing_model.dart';

/// Hợp đồng làm việc với dữ liệu tin đăng
abstract class ListingsRepository {
  Future<ListingDraft> saveDraft(ListingDraft draft, CategoryModel? category);

  /// Đăng tin. [payWithCredits]: người dùng đã đồng ý trả xu khi hết suất
  /// miễn phí (backend giữ xu, duyệt thì trừ, từ chối thì hoàn).
  /// [allowDuplicate]: vẫn đăng mới dù đã có tin giống vậy đã ẩn / hết hạn.
  Future<ListingDraft> publish(
    ListingDraft draft,
    CategoryModel? category, {
    bool payWithCredits = false,
    bool allowDuplicate = false,
  });
  Future<ListingDraft> getDraft(String id);
  Future<PagedResult<ListingModel>> mine({int page = 1, String? status});
  Future<ListingModel> detail(String id);

  /// Đổi trạng thái tin. Hiện lại tin đã hết hạn = kích hoạt lại: tính như
  /// đăng mới, hết suất miễn phí thì cần [payWithCredits].
  Future<void> changeStatus(
    String id,
    ListingStatus status, {
    bool payWithCredits = false,
  });

  /// Gia hạn tin đang hiển thị thêm [days] ngày, trả xu theo chuyên mục
  /// (giá theo ngày, tròn gói 30/60/90 thì rẻ hơn)
  Future<void> extend(String id, int days);

  /// Bật/tắt tự gia hạn (chỉ gói có hỗ trợ, ví dụ Cửa hàng)
  Future<void> setAutoExtend(String id, bool enabled);

  /// Đẩy tin đang hiển thị lên đầu 1 ngày: dùng lượt tặng của gói, hết lượt
  /// thì trả xu. Lỗi 409 ném [ListingBoostException].
  Future<BoostResult> boost(String id);

  /// Báo giá tin ưu tiên (Hot sale) của tin đang hiển thị
  Future<FeatureQuote> featureQuote(String id);

  /// Mua tin ưu tiên gói [packageId] bằng xu. Lỗi 409 ném
  /// [ListingBoostException] (FEATURE_ALREADY_ACTIVE, NOT_ENOUGH_CREDITS).
  Future<DateTime?> feature(String id, String packageId);
  Future<void> deleteDraft(String id);

  /// Số tin nháp đang giữ và giới hạn của gói
  Future<DraftQuota> draftQuota();
  Future<PagedResult<ListingModel>> browse({
    int page = 1,
    String q = '',
    String categoryId = '',
    bool exchange = false,
    GeoPoint? nearby,
  });
  Future<List<ListingModel>> favorites();
  Future<void> setFavorite(String id, bool favorite);
  Future<bool> isFavorite(String id);
}

/// Bản giả lập lưu trong bộ nhớ để làm UI trước khi có API
class MockListingsRepository implements ListingsRepository {
  MockListingsRepository({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;
  static final Map<String, ListingDraft> _store = {};
  static final Set<String> _favorites = {};
  static int _nextId = 0;
  ListingModel _model(ListingDraft draft) => ListingModel(
    id: draft.id!,
    ownerId: 'mock-user',
    title: draft.title,
    description: draft.description,
    price: draft.price,
    images: draft.images,
    categoryId: draft.categoryId,
    condition: draft.condition,
    status: draft.status,
    allowSale: draft.tradeType.allowsSale,
    allowExchange: draft.tradeType.allowsExchange,
    address: draft.address,
    attributes: draft.attributes,
    sellerName: 'Bạn',
    exchangeWish: draft.exchangeWish,
    sellerType: draft.sellerType.name.toUpperCase(),
    updatedAt: draft.updatedAt,
  );
  @override
  Future<PagedResult<ListingModel>> mine({int page = 1, String? status}) async {
    final rows =
        _store.values
            .where((draft) => status == null || draft.status.apiValue == status)
            .map(_model)
            .toList()
          // Giống API: mới sửa trước
          ..sort(
            (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(
              a.updatedAt ?? DateTime(0),
            ),
          );
    return PagedResult(
      items: rows.skip((page - 1) * 20).take(20).toList(),
      page: page,
      hasMore: page * 20 < rows.length,
    );
  }

  @override
  Future<ListingModel> detail(String id) async => _store[id] != null
      ? _model(_store[id]!)
      : ListingModel.fromJson(
          HomeMockData.listings(
            DateTime.now(),
          ).firstWhere((item) => item['id'] == id),
        );
  @override
  Future<void> changeStatus(
    String id,
    ListingStatus status, {
    bool payWithCredits = false,
  }) async {
    _store[id] = (await getDraft(id)).copyWith(status: status);
  }

  @override
  Future<void> extend(String id, int days) async {}

  @override
  Future<void> setAutoExtend(String id, bool enabled) async {}

  @override
  Future<BoostResult> boost(String id) async =>
      const BoostResult(free: false, credits: 4, freeLeft: 0);

  @override
  Future<FeatureQuote> featureQuote(String id) async => const FeatureQuote(
    discountPercent: 0,
    available: 50,
    options: [
      FeatureOption(packageId: 'featured-1', durationDays: 1, credits: 8),
      FeatureOption(packageId: 'featured-3', durationDays: 3, credits: 23),
      FeatureOption(packageId: 'featured-7', durationDays: 7, credits: 50),
    ],
  );

  @override
  Future<DateTime?> feature(String id, String packageId) async =>
      DateTime.now().add(const Duration(days: 1));

  @override
  Future<void> deleteDraft(String id) async {
    _store.remove(id);
  }

  @override
  Future<PagedResult<ListingModel>> browse({
    int page = 1,
    String q = '',
    String categoryId = '',
    bool exchange = false,
    GeoPoint? nearby,
  }) async {
    final rows = HomeMockData.listings(DateTime.now())
        .map(ListingModel.fromJson)
        .where(
          (item) =>
              item.title.toLowerCase().contains(q.toLowerCase()) &&
              (categoryId.isEmpty || item.categoryId == categoryId) &&
              (!exchange || item.allowExchange),
        )
        .toList();
    return PagedResult(
      items: rows.skip((page - 1) * 20).take(20).toList(),
      page: page,
      hasMore: page * 20 < rows.length,
    );
  }

  @override
  Future<List<ListingModel>> favorites() async => (await browse()).items
      .where((item) => _favorites.contains(item.id))
      .toList();
  @override
  Future<void> setFavorite(String id, bool favorite) async {
    favorite ? _favorites.add(id) : _favorites.remove(id);
  }

  @override
  Future<bool> isFavorite(String id) async => _favorites.contains(id);

  @override
  Future<ListingDraft> getDraft(String id) async =>
      _store[id] ?? (throw StateError('Không tìm thấy nháp.'));

  @override
  Future<DraftQuota> draftQuota() async => DraftQuota(
    used: _store.values
        .where((draft) => draft.status == ListingStatus.draft)
        .length,
    limit: DraftQuota.mockLimitFor(DevPlanOverride.plan.value),
  );

  String _newId() =>
      'listing_${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';

  @override
  Future<ListingDraft> saveDraft(
    ListingDraft draft,
    CategoryModel? category,
  ) async {
    await Future<void>.delayed(latency);
    // Backend cũng chặn khi đã giữ đủ số tin nháp của gói
    if (_store[draft.id]?.status != ListingStatus.draft &&
        (await draftQuota()).isFull) {
      throw ListingSaveException(draft, const DraftLimitReachedException());
    }
    final saved = draft.copyWith(
      id: draft.id ?? _newId(),
      status: ListingStatus.draft,
      updatedAt: DateTime.now(),
    );
    _store[saved.id!] = saved;
    return saved;
  }

  @override
  Future<ListingDraft> publish(
    ListingDraft draft,
    CategoryModel? category, {
    bool payWithCredits = false,
    bool allowDuplicate = false,
  }) async {
    await Future<void>.delayed(latency);
    final categoryId = draft.categoryId;
    var alreadyCounted = _store[draft.id]?.status == ListingStatus.pending;
    // Backend cũng chặn khi chuyên mục đã đủ số tin của tài khoản cá nhân;
    // đồng ý trả xu thì tin không chiếm suất miễn phí
    if (categoryId.isNotEmpty && !alreadyCounted) {
      final used = MockPostingQuotaStore.used[categoryId] ?? 0;
      if (used >= MockPostingQuotaStore.limitOf(categoryId)) {
        if (!payWithCredits) {
          throw ListingSaveException(
            draft,
            const PostingLimitReachedException(),
          );
        }
        alreadyCounted = true;
      }
    }
    // Tin mới cần admin duyệt trước khi hiển thị (SRS 4.2)
    final published = draft.copyWith(
      id: draft.id ?? _newId(),
      status: ListingStatus.pending,
      updatedAt: DateTime.now(),
    );
    _store[published.id!] = published;
    if (categoryId.isNotEmpty && !alreadyCounted) {
      MockPostingQuotaStore.recordPublished(categoryId);
    }
    return published;
  }
}

/// Ảnh không tải lên được vì [problem]; báo trước khi gửi lên máy chủ
class ListingImageException implements Exception {
  const ListingImageException(this.problem, {this.paths = const []});
  final ListingImageProblem problem;

  /// Ảnh trên máy gây lỗi (VD file ảnh đã bị xóa khỏi máy)
  final List<String> paths;

  @override
  String toString() => 'ListingImageException($problem, $paths)';
}

/// [missing]: file ảnh đã chọn không còn trên máy (bộ nhớ tạm bị dọn)
enum ListingImageProblem { tooLarge, unsupported, missing }

/// Tin cũ trùng với tin đang đăng. [active]: tin cũ đang hiển thị / chờ
/// duyệt (không đăng được), ngược lại tin cũ đã ẩn / hết hạn (nên kích hoạt lại)
/// Kết quả đẩy tin: [free] = dùng lượt tặng của gói, không thì trả [credits] xu
class BoostResult {
  const BoostResult({
    required this.free,
    required this.credits,
    required this.freeLeft,
  });
  final bool free;
  final int credits;

  /// Lượt đẩy tin miễn phí còn lại trong tháng
  final int freeLeft;

  factory BoostResult.fromJson(Map<String, dynamic> json) => BoostResult(
    free: json['free'] == true,
    credits: (json['credits'] as num?)?.toInt() ?? 0,
    freeLeft: (json['freeLeft'] as num?)?.toInt() ?? 0,
  );
}

/// Một gói tin ưu tiên: [credits] xu cho [durationDays] ngày ở mục Hot sale
class FeatureOption {
  const FeatureOption({
    required this.packageId,
    required this.durationDays,
    required this.credits,
  });
  final String packageId;
  final int durationDays;
  final int credits;

  factory FeatureOption.fromJson(Map<String, dynamic> json) => FeatureOption(
    packageId: '${json['packageId']}',
    durationDays: (json['durationDays'] as num?)?.toInt() ?? 1,
    credits: (json['credits'] as num?)?.toInt() ?? 0,
  );
}

/// Báo giá tin ưu tiên: giá đã giảm theo gói ([discountPercent]), số xu
/// đang có, [runningUntil] khác null khi tin đang ở Hot sale
class FeatureQuote {
  const FeatureQuote({
    required this.discountPercent,
    required this.available,
    required this.options,
    this.runningUntil,
  });
  final int discountPercent;
  final int available;
  final List<FeatureOption> options;
  final DateTime? runningUntil;

  factory FeatureQuote.fromJson(Map<String, dynamic> json) => FeatureQuote(
    discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
    available: (json['available'] as num?)?.toInt() ?? 0,
    runningUntil: DateTime.tryParse('${json['runningUntil']}')?.toLocal(),
    options: [
      for (final option in (json['options'] as List? ?? const []))
        if (option is Map)
          FeatureOption.fromJson(Map<String, dynamic>.from(option)),
    ],
  );
}

/// Backend từ chối đẩy tin / tin ưu tiên (HTTP 409): [code] như
/// `BOOST_TOO_SOON`, `FEATURE_ALREADY_ACTIVE`, `NOT_ENOUGH_CREDITS`,
/// `LISTING_NOT_BOOSTABLE`
class ListingBoostException implements Exception {
  const ListingBoostException(
    this.code, {
    this.message,
    this.details = const {},
  });
  final String code;
  final String? message;
  final Map<String, dynamic> details;

  static const tooSoon = 'BOOST_TOO_SOON';
  static const featureActive = 'FEATURE_ALREADY_ACTIVE';
  static const notEnoughCredits = 'NOT_ENOUGH_CREDITS';

  @override
  String toString() => 'ListingBoostException($code)';
}

class DuplicateListing {
  const DuplicateListing({required this.listingId, required this.active});
  final String listingId;
  final bool active;

  static const activeCode = 'DUPLICATE_LISTING';
  static const inactiveCode = 'DUPLICATE_INACTIVE';
}

/// Lưu / đăng tin lỗi giữa chừng. [draft] là bản đã lưu được tới lúc lỗi
/// (đã có id, ảnh đã tải) để thử lại không tạo tin trùng, không tải lại ảnh.
class ListingSaveException implements Exception {
  const ListingSaveException(this.draft, this.cause);
  final ListingDraft draft;
  final Object cause;

  /// Ảnh quá lớn / sai định dạng
  ListingImageProblem? get imageProblem {
    final error = cause;
    return error is ListingImageException ? error.problem : null;
  }

  /// Ảnh trên máy gây lỗi, VD ảnh không còn trên máy để bỏ khỏi tin
  List<String> get imagePaths {
    final error = cause;
    return error is ListingImageException ? error.paths : const [];
  }

  /// Không tới được máy chủ hoặc chờ quá lâu
  bool get isNetworkError {
    final error = cause;
    return error is DioException &&
        const {
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        }.contains(error.type);
  }

  /// Câu báo lỗi máy chủ trả về (`error`), nếu có
  String? get serverMessage {
    final error = cause;
    if (error is! DioException) return null;
    final data = error.response?.data;
    final message = data is Map ? data['error'] : null;
    return message is String && message.trim().isNotEmpty ? message : null;
  }

  @override
  String toString() => 'ListingSaveException(${draft.id}, $cause)';

  /// Chuyên mục đã đủ số tin cho phép (API trả 409 `POSTING_LIMIT_REACHED`)
  /// hoặc đồng ý trả xu nhưng ví không đủ (`NOT_ENOUGH_CREDITS`)
  bool get isPostingLimitReached {
    final error = cause;
    if (error is PostingLimitReachedException) return true;
    final code = _conflictCode;
    return code == PostingLimitReachedException.code ||
        code == PostingLimitReachedException.notEnoughCredits;
  }

  /// Ví không đủ xu (`NOT_ENOUGH_CREDITS`): số xu còn thiếu, null nếu không phải lỗi này
  int? get missingCredits {
    if (_conflictCode != PostingLimitReachedException.notEnoughCredits) {
      return null;
    }
    final data = (cause as DioException).response?.data as Map;
    final details = data['details'] is Map ? data['details'] as Map : const {};
    return (details['missing'] as num?)?.toInt() ?? 0;
  }

  /// Đã có tin giống vậy (API trả 409 `DUPLICATE_LISTING` khi tin cũ đang
  /// hiển thị / chờ duyệt, `DUPLICATE_INACTIVE` khi đã ẩn / hết hạn)
  DuplicateListing? get duplicate {
    final code = _conflictCode;
    if (code != DuplicateListing.activeCode &&
        code != DuplicateListing.inactiveCode) {
      return null;
    }
    final data = (cause as DioException).response?.data as Map;
    final details = data['details'] is Map ? data['details'] as Map : const {};
    return DuplicateListing(
      listingId: '${details['listingId'] ?? ''}',
      active: code == DuplicateListing.activeCode,
    );
  }

  /// Đã giữ đủ số tin nháp của gói (API trả 409 `DRAFT_LIMIT_REACHED`)
  bool get isDraftLimitReached {
    if (cause is DraftLimitReachedException) return true;
    return _conflictCode == DraftLimitReachedException.code;
  }

  String? get _conflictCode {
    final error = cause;
    if (error is! DioException || error.response?.statusCode != 409) {
      return null;
    }
    final data = error.response?.data;
    return data is Map ? '${data['code']}' : null;
  }
}

class ApiListingsRepository implements ListingsRepository {
  ApiListingsRepository({
    ApiClient? apiClient,
    Dio? dio,
    Future<Uint8List> Function(String)? readImage,
  }) : _dio = dio ?? (apiClient ?? ApiClient()).dio,
       _readImage = readImage ?? ((path) => XFile(path).readAsBytes());
  final Dio _dio;
  final Future<Uint8List> Function(String) _readImage;
  String _imageUrl(String value) => value.startsWith('/api/')
      ? '${Uri.parse(_dio.options.baseUrl).origin}$value'
      : value;
  String? _remotePath(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.hasScheme &&
        uri.scheme != 'http' &&
        uri.scheme != 'https') {
      return null;
    }
    if (uri == null ||
        (uri.hasScheme &&
            uri.origin != Uri.parse(_dio.options.baseUrl).origin)) {
      return null;
    }
    return uri.path.startsWith('/api/v1/listings/media/') ? uri.path : null;
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing listing data');
    return Map<String, dynamic>.from(data);
  }

  ListingDraft _merge(
    ListingDraft draft,
    Map<String, dynamic> data, {
    List<String>? images,
  }) {
    final status = ListingStatus.fromApi(data['status'] as String?);
    if (status == null) throw const FormatException('Missing listing status');
    return draft.copyWith(
      id: data['id'] as String,
      status: status,
      images:
          images ??
          (data['images'] as List).cast<String>().map(_imageUrl).toList(),
      updatedAt: DateTime.tryParse('${data['updatedAt']}'),
    );
  }

  @override
  Future<ListingDraft> saveDraft(ListingDraft draft, CategoryModel? category) =>
      _saveDraft(draft, category, publish: false);

  /// Đăng tin thẳng (`POST /listings`, tin vào hàng chờ duyệt) rồi tải ảnh lên.
  /// Bản nháp đã lưu trên máy chủ thì đăng qua luồng nháp như cũ.
  @override
  Future<ListingDraft> publish(
    ListingDraft draft,
    CategoryModel? category, {
    bool payWithCredits = false,
    bool allowDuplicate = false,
  }) {
    if (draft.id != null && draft.status == ListingStatus.draft) {
      return _saveDraft(
        draft,
        category,
        publish: true,
        payWithCredits: payWithCredits,
        allowDuplicate: allowDuplicate,
      );
    }
    return _publishListing(
      draft,
      category,
      payWithCredits: payWithCredits,
      allowDuplicate: allowDuplicate,
    );
  }

  Future<ListingDraft> _publishListing(
    ListingDraft draft,
    CategoryModel? category, {
    bool payWithCredits = false,
    bool allowDuplicate = false,
  }) async {
    var working = draft;
    try {
      final payload = {
        ...draft.toPayload(category: category),
        if (payWithCredits) 'payWithCredits': true,
        if (allowDuplicate) 'allowDuplicate': true,
      };
      // Lần đầu: tạo tin mới. Thử lại sau khi tải ảnh lỗi giữa chừng: tin đã
      // tạo rồi nên chỉ cập nhật nội dung (không tạo trùng, không trừ thêm lượt)
      final response = draft.id == null
          ? await _dio.post<Map<String, dynamic>>('/listings', data: payload)
          : await _dio.put<Map<String, dynamic>>(
              '/listings/${Uri.encodeComponent(draft.id!)}',
              data: payload,
            );
      working = _merge(draft, _data(response), images: draft.images);
      return await _syncImages(working, (next) => working = next);
    } catch (error) {
      throw ListingSaveException(working, error);
    }
  }

  Future<ListingDraft> _saveDraft(
    ListingDraft draft,
    CategoryModel? category, {
    required bool publish,
    bool payWithCredits = false,
    bool allowDuplicate = false,
  }) async {
    var working = draft;
    try {
      if (publish && draft.id != null && draft.status == ListingStatus.draft) {
        final remote = _data(
          await _dio.get<Map<String, dynamic>>(
            '/listings/mine/${Uri.encodeComponent(draft.id!)}',
          ),
        );
        if (remote['status'] == 'PENDING') return _merge(draft, remote);
      }
      final payload = draft.toPayload(category: category);
      final response = draft.id == null
          ? await _dio.post<Map<String, dynamic>>(
              '/listings/drafts',
              data: payload,
            )
          : await _dio.put<Map<String, dynamic>>(
              '/listings/drafts/${Uri.encodeComponent(draft.id!)}',
              data: payload,
            );
      working = _merge(draft, _data(response), images: draft.images);
      working = await _syncImages(working, (next) => working = next);
      if (!publish) return working;
      final id = Uri.encodeComponent(working.id!);
      final result = _data(
        await _dio.post<Map<String, dynamic>>(
          '/listings/drafts/$id/publish',
          data: {
            if (payWithCredits) 'payWithCredits': true,
            if (allowDuplicate) 'allowDuplicate': true,
          },
        ),
      );
      return _merge(working, result);
    } catch (error) {
      throw ListingSaveException(working, error);
    }
  }

  /// Đưa danh sách ảnh trên máy chủ về đúng [working.images]: bỏ ảnh đã xóa,
  /// tải ảnh mới (ảnh trên máy) theo thứ tự rồi sắp xếp lại.
  /// [onProgress] nhận bản mới sau mỗi ảnh để lỗi giữa chừng vẫn giữ ảnh đã tải.
  Future<ListingDraft> _syncImages(
    ListingDraft working,
    void Function(ListingDraft) onProgress,
  ) async {
    final id = Uri.encodeComponent(working.id!);
    // Đọc hết ảnh trên máy trước khi đổi gì trên máy chủ: thiếu ảnh nào thì
    // báo đủ một lần để người dùng chọn lại
    final local = <String, Uint8List>{};
    final missing = <String>[];
    for (final image in working.images) {
      if (_remotePath(image) != null) continue;
      try {
        local[image] = await _readImage(image);
      } on Exception catch (error) {
        debugPrint('Không đọc được ảnh $image: $error');
        missing.add(image);
      }
    }
    if (missing.isNotEmpty) {
      throw ListingImageException(ListingImageProblem.missing, paths: missing);
    }
    final retained = working.images
        .map(_remotePath)
        .whereType<String>()
        .toList();
    // Free removed slots before uploading replacements. URLs must already belong to this listing.
    await _dio.put<void>('/listings/$id/images', data: {'images': retained});
    final images = [...working.images];
    for (var index = 0; index < images.length; index++) {
      if (_remotePath(images[index]) != null) continue;
      final bytes = local[images[index]]!;
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw const ListingImageException(ListingImageProblem.tooLarge);
      }
      final uploaded = await _dio.post<Map<String, dynamic>>(
        '/listings/$id/images',
        data: bytes,
        // Ảnh vài MB qua mạng chậm cần lâu hơn timeout mặc định (10 giây)
        options: Options(
          contentType: _imageContentType(bytes),
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      );
      images[index] = _imageUrl(_data(uploaded)['url'] as String);
      onProgress(working.copyWith(images: List<String>.from(images)));
    }
    await _dio.put<void>(
      '/listings/$id/images',
      data: {'images': images.map((image) => _remotePath(image)!).toList()},
    );
    return working.copyWith(images: images);
  }

  static const Duration _uploadTimeout = Duration(seconds: 60);

  static String _imageContentType(Uint8List bytes) =>
      bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255
      ? 'image/jpeg'
      : bytes.length >= 8 &&
            bytes[0] == 137 &&
            bytes[1] == 80 &&
            bytes[2] == 78 &&
            bytes[3] == 71
      ? 'image/png'
      : bytes.length >= 12 &&
            String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
            String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP'
      ? 'image/webp'
      : throw const ListingImageException(ListingImageProblem.unsupported);

  @override
  Future<ListingDraft> getDraft(String id) async {
    final data = _data(
      await _dio.get<Map<String, dynamic>>(
        '/listings/mine/${Uri.encodeComponent(id)}',
      ),
    );
    return ListingDraft.fromListing(_listing(data));
  }

  ListingModel _listing(Map<String, dynamic> data) =>
      ListingModel.fromJson(data, apiBaseUrl: _dio.options.baseUrl);
  @override
  Future<PagedResult<ListingModel>> mine({int page = 1, String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings/mine',
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (status != null) 'status': status,
      },
    );
    return PagedResult.fromJson(
      response.data!,
      _listing,
      page: page,
      pageSize: 20,
    );
  }

  @override
  Future<ListingModel> detail(String id) async => _listing(
    _data(
      await _dio.get<Map<String, dynamic>>(
        '/listings/${Uri.encodeComponent(id)}',
      ),
    ),
  );
  @override
  Future<void> changeStatus(
    String id,
    ListingStatus status, {
    bool payWithCredits = false,
  }) => _dio.patch<void>(
    '/listings/${Uri.encodeComponent(id)}/status',
    data: {
      'status': status.apiValue,
      if (payWithCredits) 'payWithCredits': true,
    },
  );

  @override
  Future<void> extend(String id, int days) => _dio.post<void>(
    '/listings/${Uri.encodeComponent(id)}/extend',
    data: {'days': days},
  );

  @override
  Future<void> setAutoExtend(String id, bool enabled) => _dio.patch<void>(
    '/listings/${Uri.encodeComponent(id)}/auto-extend',
    data: {'enabled': enabled},
  );

  @override
  Future<BoostResult> boost(String id) => _promotion(
    () async => BoostResult.fromJson(
      _data(
        await _dio.post<Map<String, dynamic>>(
          '/listings/${Uri.encodeComponent(id)}/boost',
        ),
      ),
    ),
  );

  @override
  Future<FeatureQuote> featureQuote(String id) async => FeatureQuote.fromJson(
    _data(
      await _dio.get<Map<String, dynamic>>(
        '/listings/${Uri.encodeComponent(id)}/feature',
      ),
    ),
  );

  @override
  Future<DateTime?> feature(String id, String packageId) => _promotion(
    () async => DateTime.tryParse(
      '${_data(await _dio.post<Map<String, dynamic>>('/listings/${Uri.encodeComponent(id)}/feature', data: {'packageId': packageId}))['endsAt']}',
    )?.toLocal(),
  );

  /// Đổi lỗi 409 của đẩy tin / tin ưu tiên thành [ListingBoostException]
  Future<T> _promotion<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (error.response?.statusCode != 409 || data is! Map) rethrow;
      final details = data['details'];
      throw ListingBoostException(
        '${data['code']}',
        message: data['error'] as String?,
        details: details is Map ? Map<String, dynamic>.from(details) : const {},
      );
    }
  }

  @override
  Future<void> deleteDraft(String id) async {
    try {
      await _dio.delete<void>('/listings/drafts/${Uri.encodeComponent(id)}');
    } on DioException catch (error) {
      // Không còn tin nháp này (đã xóa ở nơi khác) thì coi như xóa xong
      if (error.response?.statusCode != 404) rethrow;
    }
  }

  @override
  Future<DraftQuota> draftQuota() async => DraftQuota.fromJson(
    _data(await _dio.get<Map<String, dynamic>>('/listings/drafts/quota')),
  );

  @override
  Future<PagedResult<ListingModel>> browse({
    int page = 1,
    String q = '',
    String categoryId = '',
    bool exchange = false,
    GeoPoint? nearby,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings',
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (q.isNotEmpty) 'q': q,
        if (categoryId.isNotEmpty) 'categoryId': categoryId,
        if (exchange) 'allowExchange': 'true',
        if (nearby != null) ...nearby.toJson(),
        if (nearby != null) 'radiusKm': 5,
      },
    );
    return PagedResult.fromJson(
      response.data!,
      _listing,
      page: page,
      pageSize: 20,
    );
  }

  @override
  Future<List<ListingModel>> favorites() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings/favorites',
    );
    return (response.data!['data'] as List)
        .map((item) => _listing(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> setFavorite(String id, bool favorite) => favorite
      ? _dio.put<void>('/listings/${Uri.encodeComponent(id)}/favorite')
      : _dio.delete<void>('/listings/${Uri.encodeComponent(id)}/favorite');
  @override
  Future<bool> isFavorite(String id) async =>
      (await _dio.get<Map<String, dynamic>>(
        '/listings/${Uri.encodeComponent(id)}/favorite',
      )).data!['data'] ==
      true;
}
