import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:restore/core/network/api_client.dart';

import '../models/product_detail.dart';
import '../../chat/repositories/chat_repository.dart';

/// Nguồn dữ liệu trang chi tiết sản phẩm và các hành động của người mua
abstract class ProductDetailRepository {
  Future<ProductDetail> getDetail(String listingId);
  Future<void> setFavorite(String listingId, bool favorite);

  /// Phát mỗi khi tin vừa được sửa, đổi trạng thái, duyệt hoặc bán
  Stream<void> changes(String listingId);

  /// Mở (hoặc tạo) cuộc trò chuyện với người bán về tin này, trả về id
  Future<String> openConversation(String listingId);

  /// Gửi đề nghị giá [amount] (VND), trả về id cuộc trò chuyện với người bán
  Future<String> sendOffer(String listingId, int amount);

  /// Gửi yêu cầu mua đúng giá niêm yết, trả về id cuộc trò chuyện
  Future<String> requestPurchase(String listingId, {String? note});
}

/// Gọi backend, hợp đồng API xem listing-api-contract.md (mục "Chi tiết tin")
class ApiProductDetailRepository implements ProductDetailRepository {
  ApiProductDetailRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<ProductDetail> getDetail(String listingId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/$listingId',
    );
    return ProductDetail.fromJson(_data(response.data));
  }

  /// `GET /listings/:id/events` (SSE). Trình duyệt (XHR của Dio) gom cả luồng nên web
  /// không mở kết nối này; trang chi tiết vẫn tự tải lại theo chu kỳ
  @override
  Stream<void> changes(String listingId) async* {
    if (kIsWeb) return;
    final cancelToken = CancelToken();
    try {
      final response = await _apiClient.dio.get<ResponseBody>(
        '/listings/$listingId/events',
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,
        ),
      );
      yield* response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.startsWith('event: changed'))
          .map((_) {});
    } finally {
      cancelToken.cancel();
    }
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.post<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }

  @override
  Future<String> openConversation(String listingId) async {
    final detail = await getDetail(listingId);
    return ApiChatRepository(
      apiClient: _apiClient,
    ).startConversation(detail.seller.id, listingId: listingId);
  }

  @override
  Future<String> sendOffer(String listingId, int amount) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/listings/$listingId/offers',
      data: {'amount': amount},
    );
    return '${_data(response.data)['conversationId']}';
  }

  @override
  Future<String> requestPurchase(String listingId, {String? note}) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/listings/$listingId/purchase-requests',
      data: {'note': ?note},
    );
    return '${_data(response.data)['conversationId']}';
  }

  Map<String, dynamic> _data(Map<String, dynamic>? json) {
    final data = json?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return Map<String, dynamic>.from(data);
  }
}
