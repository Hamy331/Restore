import 'package:restore/core/network/api_client.dart';

import '../models/product_detail.dart';

/// Nguồn dữ liệu trang chi tiết sản phẩm và các hành động của người mua
abstract class ProductDetailRepository {
  Future<ProductDetail> getDetail(String listingId);
  Future<void> setFavorite(String listingId, bool favorite);

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

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.post<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }

  @override
  Future<String> openConversation(String listingId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/conversations',
      data: {'listingId': listingId},
    );
    return '${_data(response.data)['id']}';
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
