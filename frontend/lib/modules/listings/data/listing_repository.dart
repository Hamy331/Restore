import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import '../domain/entities/listing_preview.dart';

class ListingPage {
  const ListingPage(this.items, this.totalItems, this.totalPages);
  final List<ListingPreview> items;
  final int totalItems;
  final int totalPages;
}

class ListingRepository {
  ListingRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;
  final Dio _dio;

  Future<String> uploadImage(
    String id,
    Uint8List bytes,
    String contentType,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/listings/${Uri.encodeComponent(id)}/images',
      data: bytes,
      options: Options(contentType: contentType),
    );
    return ListingPreview.resolveImage(
      (response.data!['data'] as Map<String, dynamic>)['url'] as String,
    );
  }

  Future<void> replaceImages(String id, List<String> urls) async {
    await _dio.put<void>(
      '/listings/${Uri.encodeComponent(id)}/images',
      data: {'images': urls.map((url) => Uri.parse(url).path).toList()},
    );
  }

  Future<ListingPage> list({int page = 1, String query = ''}) =>
      search(page: page, query: query);

  Future<ListingPage> search({
    int page = 1,
    String query = '',
    String categoryId = '',
    String condition = '',
    String minPrice = '',
    String maxPrice = '',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings',
      queryParameters: {
        'page': page,
        'pageSize': 12,
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId.isNotEmpty) 'categoryId': categoryId,
        if (condition.isNotEmpty) 'condition': condition,
        if (minPrice.isNotEmpty) 'minPrice': minPrice,
        if (maxPrice.isNotEmpty) 'maxPrice': maxPrice,
      },
    );
    final body = response.data!;
    final pagination = body['pagination'] as Map<String, dynamic>;
    return ListingPage(
      (body['data'] as List)
          .map((item) => ListingPreview.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination['totalItems'] as int,
      pagination['totalPages'] as int,
    );
  }

  Future<ListingPreview> get(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings/${Uri.encodeComponent(id)}',
    );
    return ListingPreview.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<ListingPreview> create({
    required String title,
    required String description,
    required String price,
    required String condition,
    required String categoryId,
    required bool isNegotiable,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/listings',
      data: {
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'categoryId': categoryId,
        'isNegotiable': isNegotiable,
      },
    );
    return ListingPreview.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ListingPreview>> mineAvailable() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings/mine',
      queryParameters: {'status': 'AVAILABLE', 'pageSize': 100},
    );
    return (response.data!['data'] as List)
        .map((item) => ListingPreview.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ListingPage> mine({int page = 1, String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings/mine',
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (status != null) 'status': status,
      },
    );
    final body = response.data!;
    final pagination = body['pagination'] as Map<String, dynamic>;
    return ListingPage(
      (body['data'] as List)
          .map((item) => ListingPreview.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination['totalItems'] as int,
      pagination['totalPages'] as int,
    );
  }

  Future<ListingPreview> getMine(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/listings/mine/${Uri.encodeComponent(id)}',
    );
    return ListingPreview.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<ListingPreview> update(
    String id, {
    required String title,
    required String description,
    required String price,
    required String condition,
    required String categoryId,
    required bool isNegotiable,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/listings/${Uri.encodeComponent(id)}',
      data: {
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'categoryId': categoryId,
        'isNegotiable': isNegotiable,
      },
    );
    return ListingPreview.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<ListingPreview> changeStatus(String id, String status) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/listings/${Uri.encodeComponent(id)}/status',
      data: {'status': status},
    );
    return ListingPreview.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
