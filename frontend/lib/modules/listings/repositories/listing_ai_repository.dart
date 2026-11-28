import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'listings_repository.dart'
    show ApiListingsRepository, ListingImageException, ListingImageProblem;

/// Gợi ý AI soạn từ ảnh bìa. [prohibited]: AI nghi món là hàng cấm giao dịch,
/// [reason] nói vì sao. Chỉ là gợi ý, người bán tự sửa lại.
class ListingAiSuggestion {
  const ListingAiSuggestion({
    required this.title,
    required this.description,
    required this.condition,
    required this.prohibited,
    required this.reason,
  });

  factory ListingAiSuggestion.fromJson(Map<String, dynamic> json) =>
      ListingAiSuggestion(
        title: '${json['title'] ?? ''}'.trim(),
        description: '${json['description'] ?? ''}'.trim(),
        condition: ListingCondition.fromApi(json['condition'] as String?),
        prohibited: json['prohibited'] == true,
        reason: '${json['reason'] ?? ''}'.trim(),
      );

  final String title;
  final String description;
  final ListingCondition? condition;
  final bool prohibited;
  final String reason;
}

/// AI không soạn được. [code]: mã lỗi API (VD `AI_NOT_CONFIGURED`,
/// `RATE_LIMITED`), [message]: câu báo của máy chủ nếu có.
class ListingAiException implements Exception {
  const ListingAiException({this.code, this.message});

  final String? code;
  final String? message;
}

/// AI soạn tin (`POST /listings/ai/compose`): gửi ảnh bìa, nhận gợi ý tiêu
/// đề, mô tả, tình trạng và cảnh báo hàng cấm. Không lưu gì trên máy chủ.
class ListingAiRepository {
  ListingAiRepository({Dio? dio, Future<Uint8List> Function(String)? readImage})
    : _dio = dio ?? ApiClient().dio,
      _readImage = readImage ?? ((path) => XFile(path).readAsBytes());

  final Dio _dio;
  final Future<Uint8List> Function(String) _readImage;

  static const Duration _timeout = Duration(seconds: 60);

  Future<ListingAiSuggestion> compose(
    String image, {
    String? categoryId,
  }) async {
    final bytes = await _bytes(image);
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const ListingImageException(ListingImageProblem.tooLarge);
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/listings/ai/compose',
        data: bytes,
        queryParameters: {
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
        },
        options: Options(
          contentType: ApiListingsRepository.imageContentType(bytes),
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      final data = response.data?['data'];
      if (data is! Map) throw const ListingAiException();
      return ListingAiSuggestion.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      final data = error.response?.data;
      throw ListingAiException(
        code: data is Map ? '${data['code']}' : null,
        message: data is Map && data['error'] is String
            ? data['error'] as String
            : null,
      );
    }
  }

  /// Ảnh trên máy đọc thẳng; ảnh đã tải lên (tin nháp, tin đang sửa) lấy bản
  /// thu nhỏ 960px cho nhẹ
  Future<Uint8List> _bytes(String image) async {
    final uri = Uri.tryParse(image);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final response = await _dio.get<List<int>>(
        image,
        queryParameters: {'w': 960},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    }
    return _readImage(image);
  }
}
