import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/wanted_alert_model.dart';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/modules/listings/data/listing_mock_data.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/data/listing_filter_mock_data.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/wanted_alert_mock_data.dart';
import '../models/wanted_alert_draft.dart';
import '../models/wanted_alert_item.dart';
import '../models/wanted_alert_match.dart';
import '../utils/wanted_alert_matcher.dart';

/// Nguồn dữ liệu tính năng "Báo khi có hàng" (wanted alert).
/// Hợp đồng API và cách backend so khớp: `backend/docs/wanted-alerts.md`.
abstract class WantedAlertRepository {
  /// Số tin khớp mỗi lượt tải ở trang chi tiết
  static const int pageSize = 10;

  /// Số tin gợi ý tối đa khi soạn thông báo
  static const int previewLimit = 20;

  /// Thông báo của người dùng, mới tạo trước
  Future<List<WantedAlertItem>> getAlerts();

  Future<WantedAlertItem> getAlert(String id);

  /// Tin đang có gần giống [draft] (cùng cách chấm điểm với lúc báo tin
  /// mới), điểm cao trước
  Future<List<WantedAlertMatch>> preview(WantedAlertDraft draft);

  Future<WantedAlertItem> create(WantedAlertDraft draft);

  /// Xoá là dừng hẳn, backend không gửi thêm thông báo nào cho [id]
  Future<void> delete(String id);

  /// Tin đã khớp [alertId], khớp gần nhất trước, [page] bắt đầu từ 1
  Future<PagedResult<WantedAlertMatch>> getMatches(
    String alertId, {
    int page = 1,
  });

  /// Đánh dấu đã xem mọi tin khớp (xoá nhãn "Mới" và số đếm)
  Future<void> markSeen(String alertId);

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Dữ liệu mẫu giữ trong bộ nhớ (còn nguyên khi mở lại trang), chấm điểm
/// tin mẫu bằng [WantedAlertMatcher] giống cách backend làm.
class MockWantedAlertRepository implements WantedAlertRepository {
  MockWantedAlertRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  static List<Map<String, dynamic>>? _alerts;
  static int _nextId = 100;

  List<Map<String, dynamic>> get _store =>
      _alerts ??= WantedAlertMockData.alerts(DateTime.now());

  @override
  Future<List<WantedAlertItem>> getAlerts() async {
    await Future<void>.delayed(latency);
    return [for (final json in _store) _toItem(json)];
  }

  @override
  Future<WantedAlertItem> getAlert(String id) async {
    await Future<void>.delayed(latency);
    return _toItem(_find(id));
  }

  @override
  Future<List<WantedAlertMatch>> preview(WantedAlertDraft draft) async {
    await Future<void>.delayed(latency);
    if (!draft.hasKeywords) return const [];
    final alert = WantedAlertModel.fromJson({
      'id': 'preview',
      ...draft.toJson(),
    });
    return _score(alert).take(WantedAlertRepository.previewLimit).toList();
  }

  @override
  Future<WantedAlertItem> create(WantedAlertDraft draft) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now().toIso8601String();
    final categoryId = draft.filter.categoryId;
    final json = {
      'id': 'alert-${_nextId++}',
      'userId': 'user_me',
      ...draft.toJson(),
      if (categoryId != null) 'category': _category(categoryId),
      'createdAt': now,
      'seenAt': now,
    };
    _store.insert(0, json);
    return _toItem(json);
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(latency);
    _store.removeWhere((json) => json['id'] == id);
  }

  @override
  Future<PagedResult<WantedAlertMatch>> getMatches(
    String alertId, {
    int page = 1,
  }) async {
    await Future<void>.delayed(latency);
    final matches = _matches(_find(alertId));
    const size = WantedAlertRepository.pageSize;
    final start = (page - 1) * size;
    return PagedResult(
      items: matches.skip(start).take(size).toList(),
      page: page,
      hasMore: start + size < matches.length,
    );
  }

  @override
  Future<void> markSeen(String alertId) async {
    _find(alertId)['seenAt'] = DateTime.now().toIso8601String();
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    MockFavoriteStore.set(listingId, favorite);
  }

  Map<String, dynamic> _find(String id) => _store.firstWhere(
    (json) => json['id'] == id,
    orElse: () => throw StateError('Wanted alert $id not found'),
  );

  WantedAlertItem _toItem(Map<String, dynamic> json) {
    final matches = _matches(json);
    return WantedAlertItem.fromJson({
      ...json,
      'lastMatchedAt': matches.isEmpty
          ? null
          : matches.first.matchedAt?.toIso8601String(),
      'matchCount': matches.length,
      'newMatchCount': matches.where((match) => match.isNew).length,
      'previewImages': [
        for (final match in matches.take(3)) ?match.item.listing.coverImage,
      ],
    });
  }

  /// Tin đã khớp: tin đăng sau khi tạo thông báo (backend chỉ báo tin mới).
  /// Thông báo mẫu có sẵn được tạo từ lâu nên khớp cả tin mẫu cũ.
  List<WantedAlertMatch> _matches(Map<String, dynamic> json) {
    final alert = WantedAlertModel.fromJson(json);
    final seenAt = DateTime.tryParse('${json['seenAt']}');
    final createdAt = alert.createdAt;
    final matches = [
      for (final match in _score(alert))
        if (createdAt == null ||
            match.item.listing.createdAt?.isAfter(createdAt) != false)
          WantedAlertMatch(
            item: match.item,
            score: match.score,
            // Backend chấm điểm ngay khi tin được đăng
            matchedAt: match.item.listing.createdAt,
            isNew:
                seenAt != null &&
                match.item.listing.createdAt?.isAfter(seenAt) == true,
          ),
    ];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return matches
      ..sort((a, b) => (b.matchedAt ?? epoch).compareTo(a.matchedAt ?? epoch));
  }

  /// Chấm điểm mọi tin mẫu theo [alert], lọc cứng theo tiêu chí rồi giữ
  /// tin đạt ngưỡng, điểm cao trước
  List<WantedAlertMatch> _score(WantedAlertModel alert) {
    // Tin mẫu đều ở TP.HCM, chọn khu vực khác thì không có tin nào khớp
    final areaCode = alert.areaCode;
    if (areaCode != null &&
        !areaCode.startsWith(WantedAlertMockData.mockListingProvinceCode)) {
      return const [];
    }
    final matches = <WantedAlertMatch>[];
    for (final json in HomeMockData.listings(DateTime.now())) {
      final item = ListingCardItem.fromJson(json);
      final listing = item.listing;
      if (!alert.filter.matches(listing)) continue;
      final score = WantedAlertMatcher.score(
        alert.keywords,
        listing.title,
        description: listing.description,
      );
      if (score < alert.matchLevel.threshold) continue;
      matches.add(
        WantedAlertMatch(
          item: item.copyWith(
            isFavorite: MockFavoriteStore.contains(listing.id),
          ),
          score: score,
        ),
      );
    }
    return matches..sort((a, b) => b.score.compareTo(a.score));
  }

  Map<String, dynamic>? _category(String id) {
    for (final category in ListingMockData.categories) {
      if (category['id'] == id) return {'id': id, 'name': category['name']};
    }
    return null;
  }
}

/// Gọi backend (cần đăng nhập):
/// - `GET /wanted-alerts` → `{ data: [WantedAlert + category, matchCount,
///   newMatchCount, previewImages] }`
/// - `GET /wanted-alerts/:id` → `{ data: WantedAlert + ... }`
/// - `POST /wanted-alerts/preview` body [WantedAlertDraft.toJson]
///   → `{ data: [Listing + areaLabel, isFavorite, score] }`
/// - `POST /wanted-alerts` body [WantedAlertDraft.toJson] → `{ data: ... }`
/// - `DELETE /wanted-alerts/:id`
/// - `GET /wanted-alerts/:id/matches?page=&limit=`
///   → `{ data: [Listing + ..., score, matchedAt, isNew], meta: { hasMore } }`
/// - `POST /wanted-alerts/:id/seen`
class ApiWantedAlertRepository implements WantedAlertRepository {
  ApiWantedAlertRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _path = '/wanted-alerts';

  @override
  Future<List<WantedAlertItem>> getAlerts() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(_path);
    return [
      for (final json in _list(response.data)) WantedAlertItem.fromJson(json),
    ];
  }

  @override
  Future<WantedAlertItem> getAlert(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '$_path/$id',
    );
    return WantedAlertItem.fromJson(_object(response.data));
  }

  @override
  Future<List<WantedAlertMatch>> preview(WantedAlertDraft draft) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '$_path/preview',
      data: draft.toJson(),
      queryParameters: {'limit': WantedAlertRepository.previewLimit},
    );
    return [
      for (final json in _list(response.data)) WantedAlertMatch.fromJson(json),
    ];
  }

  @override
  Future<WantedAlertItem> create(WantedAlertDraft draft) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      _path,
      data: draft.toJson(),
    );
    return WantedAlertItem.fromJson(_object(response.data));
  }

  @override
  Future<void> delete(String id) => _apiClient.dio.delete<void>('$_path/$id');

  @override
  Future<PagedResult<WantedAlertMatch>> getMatches(
    String alertId, {
    int page = 1,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '$_path/$alertId/matches',
      queryParameters: {'page': page, 'limit': WantedAlertRepository.pageSize},
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      WantedAlertMatch.fromJson,
      page: page,
      pageSize: WantedAlertRepository.pageSize,
    );
  }

  @override
  Future<void> markSeen(String alertId) =>
      _apiClient.dio.post<void>('$_path/$alertId/seen');

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.post<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic>? json) {
    final data = json?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [for (final item in data) Map<String, dynamic>.from(item as Map)];
  }

  Map<String, dynamic> _object(Map<String, dynamic>? json) {
    final data = json?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return Map<String, dynamic>.from(data);
  }
}
