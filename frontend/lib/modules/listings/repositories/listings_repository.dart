import 'dart:typed_data';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/shared/models/geo_point.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/shared/models/paged_result.dart';
import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/category_model.dart';
import '../models/listing_draft.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/data/models/listing_model.dart';

/// Hợp đồng làm việc với dữ liệu tin đăng
abstract class ListingsRepository {
  Future<ListingDraft> saveDraft(ListingDraft draft, CategoryModel? category);
  Future<ListingDraft> publish(ListingDraft draft, CategoryModel? category);
  Future<ListingDraft> getDraft(String id);
  Future<PagedResult<ListingModel>> mine({int page = 1, String? status});
  Future<ListingModel> detail(String id);
  Future<void> changeStatus(String id, ListingStatus status);
  Future<void> deleteDraft(String id);
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
  );
  @override
  Future<PagedResult<ListingModel>> mine({int page = 1, String? status}) async {
    final rows = _store.values
        .where((draft) => status == null || draft.status.apiValue == status)
        .map(_model)
        .toList();
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
  Future<void> changeStatus(String id, ListingStatus status) async {
    _store[id] = (await getDraft(id)).copyWith(status: status);
  }

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

  String _newId() => 'listing_${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<ListingDraft> saveDraft(
    ListingDraft draft,
    CategoryModel? category,
  ) async {
    await Future<void>.delayed(latency);
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
    CategoryModel? category,
  ) async {
    await Future<void>.delayed(latency);
    // Tin mới cần admin duyệt trước khi hiển thị (SRS 4.2)
    final published = draft.copyWith(
      id: draft.id ?? _newId(),
      status: ListingStatus.pending,
      updatedAt: DateTime.now(),
    );
    _store[published.id!] = published;
    return published;
  }
}

class ListingSaveException implements Exception {
  const ListingSaveException(this.draft, this.cause);
  final ListingDraft draft;
  final Object cause;
  String get message {
    final error = cause;
    if (error is DioException && error.response?.data is Map) {
      return '${(error.response!.data as Map)['error'] ?? 'Không lưu được tin.'}';
    }
    return 'Không lưu được tin. Ảnh đã tải và ID nháp được giữ để thử lại.';
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
        (uri.hasScheme && uri.origin != Uri.parse(_dio.options.baseUrl).origin)) {
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
      _save(draft, category, false);
  @override
  Future<ListingDraft> publish(ListingDraft draft, CategoryModel? category) =>
      _save(draft, category, true);
  Future<ListingDraft> _save(
    ListingDraft draft,
    CategoryModel? category,
    bool publish,
  ) async {
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
      final data = _data(response);
      working = _merge(draft, data, images: draft.images);
      final id = Uri.encodeComponent(working.id!);
      final retained = draft.images
          .map(_remotePath)
          .whereType<String>()
          .toList();
      // Free removed slots before uploading replacements. URLs must already belong to this listing.
      await _dio.put<void>('/listings/$id/images', data: {'images': retained});
      final images = [...draft.images];
      for (var index = 0; index < images.length; index++) {
        if (_remotePath(images[index]) != null) continue;
        final bytes = await _readImage(images[index]);
        if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
          throw StateError('Mỗi ảnh tối đa 5 MB.');
        }
        final contentType =
            bytes.length >= 3 &&
                bytes[0] == 255 &&
                bytes[1] == 216 &&
                bytes[2] == 255
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
            : throw StateError('Chỉ nhận JPEG, PNG hoặc WebP.');
        final uploaded = await _dio.post<Map<String, dynamic>>(
          '/listings/$id/images',
          data: bytes,
          options: Options(contentType: contentType),
        );
        images[index] = _imageUrl(_data(uploaded)['url'] as String);
        working = working.copyWith(images: List<String>.from(images));
      }
      await _dio.put<void>(
        '/listings/$id/images',
        data: {'images': images.map((image) => _remotePath(image)!).toList()},
      );
      working = working.copyWith(images: images);
      if (!publish) return working;
      final result = _data(
        await _dio.post<Map<String, dynamic>>('/listings/drafts/$id/publish'),
      );
      return _merge(working, result);
    } catch (error) {
      throw ListingSaveException(working, error);
    }
  }

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
  Future<void> changeStatus(String id, ListingStatus status) =>
      _dio.patch<void>(
        '/listings/${Uri.encodeComponent(id)}/status',
        data: {'status': status.apiValue},
      );
  @override
  Future<void> deleteDraft(String id) =>
      _dio.delete<void>('/listings/drafts/${Uri.encodeComponent(id)}');

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
