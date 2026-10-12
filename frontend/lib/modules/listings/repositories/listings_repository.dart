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
}

/// Bản giả lập lưu trong bộ nhớ để làm UI trước khi có API
class MockListingsRepository implements ListingsRepository {
  MockListingsRepository({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;
  static final Map<String, ListingDraft> _store = {};

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

/// Gọi backend. Hợp đồng API xem tài liệu listing-api-contract.md.
class ApiListingsRepository implements ListingsRepository {
  ApiListingsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<ListingDraft> saveDraft(
    ListingDraft draft,
    CategoryModel? category,
  ) async {
    final imageUrls = await _uploadLocalImages(draft.images);
    final payload = draft.toPayload(category: category, imageUrls: imageUrls);
    final id = draft.id;
    final response = id == null
        ? await _apiClient.dio.post<Map<String, dynamic>>(
            '/listings/drafts',
            data: payload,
          )
        : await _apiClient.dio.put<Map<String, dynamic>>(
            '/listings/drafts/$id',
            data: payload,
          );
    return _merge(draft, response, imageUrls: imageUrls);
  }

  @override
  Future<ListingDraft> publish(
    ListingDraft draft,
    CategoryModel? category,
  ) async {
    final imageUrls = await _uploadLocalImages(draft.images);
    final payload = draft.toPayload(category: category, imageUrls: imageUrls);
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/listings',
      data: {...payload, 'draftId': draft.id},
    );
    return _merge(
      draft,
      response,
      imageUrls: imageUrls,
      status: ListingStatus.pending,
    );
  }

  /// Tải ảnh còn nằm trên máy lên server, ảnh đã là URL thì giữ nguyên
  Future<List<String>> _uploadLocalImages(List<String> images) async {
    final local = [
      for (final path in images)
        if (!path.startsWith('http')) path,
    ];
    if (local.isEmpty) return images;

    final form = FormData.fromMap({
      'images': [for (final path in local) await MultipartFile.fromFile(path)],
    });
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/uploads/images',
      data: form,
    );
    final urls = (response.data?['data'] as List).cast<String>();
    final uploaded = Map.fromIterables(local, urls);
    return [for (final path in images) uploaded[path] ?? path];
  }

  ListingDraft _merge(
    ListingDraft draft,
    Response<Map<String, dynamic>> response, {
    required List<String> imageUrls,
    ListingStatus? status,
  }) {
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    final listing = ListingModel.fromJson(Map<String, dynamic>.from(data));
    // Chỉ lấy id, ảnh đã tải lên và trạng thái để không ghi đè dữ liệu đang nhập
    return draft.copyWith(
      id: listing.id,
      images: imageUrls,
      status: status ?? ListingStatus.draft,
      updatedAt: listing.updatedAt ?? DateTime.now(),
    );
  }
}
