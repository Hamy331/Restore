import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/services/image_upload_service.dart';

import '../models/poster_draft.dart';
import '../models/shop_poster.dart';
import '../models/shop_poster_overview.dart';

/// Lỗi nghiệp vụ backend trả về (SHOP_REQUIRED, POSTER_SLOT_FULL...)
class ShopPosterException implements Exception {
  const ShopPosterException(this.code, {this.until});

  final String code;

  /// Hạn khóa gửi khi code = POSTER_COOLDOWN
  final DateTime? until;

  @override
  String toString() => 'ShopPosterException($code)';
}

/// Nguồn dữ liệu poster shop
abstract class ShopPosterRepository {
  factory ShopPosterRepository() => AppEnvironment.useMockData
      ? MockShopPosterRepository()
      : ApiShopPosterRepository();

  Future<ShopPosterOverview> overview();

  /// Tin đang bán của shop để gắn vào poster
  Future<List<PosterListingRef>> myListings();

  /// Tải ảnh poster đã cắt lên, trả về đường dẫn lưu vào poster
  Future<String> uploadImage(Uint8List bytes);

  Future<ShopPoster> create(PosterDraft draft);

  Future<ShopPoster> update(String id, PosterDraft draft);

  Future<ShopPoster> stop(String id);
}

/// `/shops/me/posters`
class ApiShopPosterRepository implements ShopPosterRepository {
  ApiShopPosterRepository({ApiClient? apiClient, ImageUploadService? uploader})
    : _apiClient = apiClient ?? ApiClient(),
      _uploader = uploader;

  final ApiClient _apiClient;
  final ImageUploadService? _uploader;

  Dio get _dio => _apiClient.dio;

  Future<T> _guard<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map && body['code'] is String) {
        final details = body['details'];
        throw ShopPosterException(
          body['code'] as String,
          until: details is Map
              ? DateTime.tryParse('${details['until']}')?.toLocal()
              : null,
        );
      }
      rethrow;
    }
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing poster data');
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<ShopPosterOverview> overview() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('/shops/me/posters');
    return ShopPosterOverview.fromJson(_data(response));
  });

  @override
  Future<List<PosterListingRef>> myListings() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings/promotions',
    );
    final items = _data(response)['items'] as List? ?? const [];
    return [
      for (final item in items)
        PosterListingRef.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  });

  @override
  Future<String> uploadImage(Uint8List bytes) => _guard(
    () => (_uploader ?? ImageUploadService(dio: _dio)).uploadBytes(
      bytes,
      purpose: ImagePurpose.poster,
    ),
  );

  @override
  Future<ShopPoster> create(PosterDraft draft) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/shops/me/posters',
      data: draft.toJson(),
    );
    return ShopPoster.fromJson(_data(response));
  });

  @override
  Future<ShopPoster> update(String id, PosterDraft draft) => _guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/shops/me/posters/$id',
      data: draft.toJson(),
    );
    return ShopPoster.fromJson(_data(response));
  });

  @override
  Future<ShopPoster> stop(String id) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/shops/me/posters/$id/stop',
    );
    return ShopPoster.fromJson(_data(response));
  });
}

/// Dữ liệu mẫu trong bộ nhớ, theo đúng luật của backend (2 suất, 4 poster/tháng)
class MockShopPosterRepository implements ShopPosterRepository {
  MockShopPosterRepository({
    this.latency = const Duration(milliseconds: 300),
    List<ShopPoster>? posters,
    this.activeLimit = 2,
    this.monthlyLimit = 4,
    this.hasShop = true,
  }) : _posters = posters ?? _seed();

  final Duration latency;
  final int activeLimit;
  final int monthlyLimit;
  final bool hasShop;
  final List<ShopPoster> _posters;
  var _next = 0;

  static List<ShopPoster> _seed() {
    final now = DateTime.now();
    return [
      ShopPoster(
        id: 'poster-running',
        title: 'Galaxy Week giảm tới 20%',
        imageUrl: 'assets/images/banners/shop-samsung.jpg',
        state: ShopPosterState.running,
        startsAt: now.subtract(const Duration(days: 2)),
        endsAt: now.add(const Duration(days: 5)),
        days: 7,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ShopPoster(
        id: 'poster-rejected',
        title: 'Thu cũ đổi mới',
        imageUrl: 'assets/images/banners/shop-vinfast.jpg',
        state: ShopPosterState.rejected,
        startsAt: now.add(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 8)),
        days: 7,
        rejectReason: PosterRejectReason.tooMuchText,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static const _listings = [
    PosterListingRef(id: 'l1', title: 'Samsung Galaxy S24 Ultra 256GB'),
    PosterListingRef(id: 'l2', title: 'Galaxy Tab S9 FE'),
  ];

  bool _holding(ShopPoster poster) =>
      poster.state == ShopPosterState.pending ||
      poster.state == ShopPosterState.scheduled ||
      poster.state == ShopPosterState.running;

  PosterLimits _limits() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    return PosterLimits(
      activeLimit: activeLimit,
      monthlyLimit: monthlyLimit,
      usedThisMonth: _posters
          .where(
            (p) => p.createdAt != null && !p.createdAt!.isBefore(monthStart),
          )
          .length,
      slotsInUse: _posters.where(_holding).length,
    );
  }

  @override
  Future<ShopPosterOverview> overview() async {
    await Future<void>.delayed(latency);
    return ShopPosterOverview(
      shop: hasShop
          ? const PosterShop(id: 'shop-samsung', name: 'Samsung Official Store')
          : null,
      limits: _limits(),
      posters: List.unmodifiable(_posters),
    );
  }

  @override
  Future<List<PosterListingRef>> myListings() async {
    await Future<void>.delayed(latency);
    return _listings;
  }

  @override
  Future<String> uploadImage(Uint8List bytes) async {
    await Future<void>.delayed(latency);
    return 'assets/images/banners/shop-samsung.jpg';
  }

  ShopPoster _build(String id, PosterDraft draft) {
    final now = DateTime.now();
    final start = draft.startsAt ?? now;
    return ShopPoster(
      id: id,
      title: draft.title,
      imageUrl: draft.imageUrl,
      state: ShopPosterState.pending,
      startsAt: start,
      endsAt: start.add(Duration(days: draft.days)),
      days: draft.days,
      listing: _listings
          .where((listing) => listing.id == draft.listingId)
          .firstOrNull,
      createdAt: now,
    );
  }

  bool _overlaps(ShopPoster poster, DateTime from, DateTime to) =>
      _holding(poster) &&
      (poster.endsAt?.isAfter(from) ?? true) &&
      (poster.startsAt?.isBefore(to) ?? true);

  @override
  Future<ShopPoster> create(PosterDraft draft) async {
    await Future<void>.delayed(latency);
    if (!hasShop) throw const ShopPosterException('SHOP_REQUIRED');
    final limits = _limits();
    if (limits.usedThisMonth >= monthlyLimit) {
      throw const ShopPosterException('POSTER_MONTHLY_LIMIT');
    }
    final poster = _build('poster-new-${_next++}', draft);
    if (_posters
            .where((p) => _overlaps(p, poster.startsAt!, poster.endsAt!))
            .length >=
        activeLimit) {
      throw const ShopPosterException('POSTER_SLOT_FULL');
    }
    _posters.insert(0, poster);
    return poster;
  }

  @override
  Future<ShopPoster> update(String id, PosterDraft draft) async {
    await Future<void>.delayed(latency);
    final index = _posters.indexWhere((poster) => poster.id == id);
    if (index < 0) throw const ShopPosterException('POSTER_NOT_FOUND');
    final old = _posters[index];
    final poster = _build(id, draft);
    final others = [..._posters]..removeAt(index);
    if (others
            .where((p) => _overlaps(p, poster.startsAt!, poster.endsAt!))
            .length >=
        activeLimit) {
      throw const ShopPosterException('POSTER_SLOT_FULL');
    }
    final updated = ShopPoster(
      id: id,
      title: poster.title,
      imageUrl: poster.imageUrl,
      state: ShopPosterState.pending,
      startsAt: poster.startsAt,
      endsAt: poster.endsAt,
      days: poster.days,
      listing: poster.listing,
      createdAt: old.createdAt,
    );
    _posters[index] = updated;
    return updated;
  }

  @override
  Future<ShopPoster> stop(String id) async {
    await Future<void>.delayed(latency);
    final index = _posters.indexWhere((poster) => poster.id == id);
    if (index < 0) throw const ShopPosterException('POSTER_NOT_FOUND');
    final old = _posters[index];
    final stopped = old.copyWith(
      state: ShopPosterState.stopped,
      endsAt: old.state == ShopPosterState.running ? DateTime.now() : null,
    );
    _posters[index] = stopped;
    return stopped;
  }
}
