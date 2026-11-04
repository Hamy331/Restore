import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';

import '../data/location_mock_data.dart';
import '../models/address_suggestion.dart';

/// Gợi ý số nhà, tên đường cho ô địa chỉ
abstract class AddressSuggestRepository {
  /// Gõ ít hơn số ký tự này thì chưa gợi ý
  static const int minQueryLength = 2;
  static const int limit = 6;

  /// Gợi ý cho [query], ưu tiên quanh phường/tỉnh đang chọn
  Future<List<AddressSuggestion>> suggest(
    String query, {
    String? provinceCode,
    String? wardCode,
  });
}

/// Gợi ý từ danh sách đường phố có thật ở vài thành phố lớn (đủ để thử giao
/// diện). Gõ số nhà ở đầu thì giữ lại, VD "12 ng" → "12 Nguyễn Huệ".
class MockAddressSuggestRepository implements AddressSuggestRepository {
  MockAddressSuggestRepository({
    this.latency = const Duration(milliseconds: 250),
  });

  final Duration latency;

  /// Đường phố theo mã phường (mã chính thức, xem vn_locations.json)
  static const Map<String, List<String>> _streetsByWard = {
    '26740': [
      'Nguyễn Huệ',
      'Đồng Khởi',
      'Lê Thánh Tôn',
      'Hai Bà Trưng',
      'Tôn Đức Thắng',
    ],
    '26743': [
      'Lê Lợi',
      'Lý Tự Trọng',
      'Nguyễn Thái Học',
      'Phạm Ngũ Lão',
      'Lê Lai',
    ],
    '26737': [
      'Trần Quang Khải',
      'Hai Bà Trưng',
      'Nguyễn Hữu Cầu',
      'Đinh Công Tráng',
    ],
    '27139': [
      'Nguyễn Thị Minh Khai',
      'Võ Văn Tần',
      'Nam Kỳ Khởi Nghĩa',
      'Trần Quốc Thảo',
    ],
    '26884': ['Quang Trung', 'Nguyễn Văn Bảo', 'Lê Đức Thọ', 'Phan Văn Trị'],
    '00070': [
      'Tràng Tiền',
      'Hàng Bài',
      'Đinh Tiên Hoàng',
      'Hàng Khay',
      'Lý Thái Tổ',
    ],
    '00004': ['Kim Mã', 'Đội Cấn', 'Liễu Giai', 'Nguyễn Thái Học'],
    '00166': ['Xuân Thủy', 'Cầu Giấy', 'Trần Thái Tông', 'Dịch Vọng Hậu'],
    '20242': [
      'Bạch Đằng',
      'Trần Phú',
      'Lê Duẩn',
      'Hùng Vương',
      'Nguyễn Văn Linh',
    ],
  };

  @override
  Future<List<AddressSuggestion>> suggest(
    String query, {
    String? provinceCode,
    String? wardCode,
  }) async {
    await Future<void>.delayed(latency);
    final match = RegExp(r'^\s*(\d+[\w/]*)\s+(.*)$').firstMatch(query);
    final number = match?.group(1);
    final text = (match?.group(2) ?? query).trim();
    if (text.isEmpty) return const [];

    final data = await LocationMockData.load();
    final results = <AddressSuggestion>[];
    // Phường đang chọn trước, rồi các phường cùng tỉnh, rồi nơi khác
    final entries = [
      for (var rank = 0; rank < 3; rank++)
        ..._streetsByWard.entries.where(
          (entry) => _rank(entry.key, data, wardCode, provinceCode) == rank,
        ),
    ];
    for (final MapEntry(key: code, value: streets) in entries) {
      final ward = data.allWards.where((w) => w.code == code).firstOrNull;
      if (ward == null) continue;
      if (provinceCode != null && ward.parentCode != provinceCode) continue;
      final province = data.provinceOf(ward.parentCode!);
      for (final street in streets) {
        if (!VietnameseText.matches(street, text)) continue;
        results.add(
          AddressSuggestion(
            label: number == null ? street : '$number $street',
            description: '${ward.name}, ${province?.name ?? ''}',
            provinceCode: ward.parentCode,
            wardCode: ward.code,
            point: ward.center,
          ),
        );
      }
    }
    return results.take(AddressSuggestRepository.limit).toList();
  }

  static int _rank(
    String code,
    LocationMockData data,
    String? wardCode,
    String? provinceCode,
  ) {
    if (code == wardCode) return 0;
    final ward = data.allWards.where((w) => w.code == code).firstOrNull;
    return ward?.parentCode == provinceCode ? 1 : 2;
  }
}

/// `GET /catalog/locations/address-suggest?q=&provinceCode=&wardCode=&limit=`
/// → `{ data: [{ label, description, provinceCode?, wardCode?, latitude?, longitude? }] }`.
/// Backend lấy gợi ý từ Photon (OpenStreetMap, miễn phí, không cần key).
class ApiAddressSuggestRepository implements AddressSuggestRepository {
  ApiAddressSuggestRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<AddressSuggestion>> suggest(
    String query, {
    String? provinceCode,
    String? wardCode,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/catalog/locations/address-suggest',
      queryParameters: {
        'q': query,
        if (provinceCode != null) 'provinceCode': provinceCode,
        if (wardCode != null) 'wardCode': wardCode,
        'limit': AddressSuggestRepository.limit,
      },
    );
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data)
        AddressSuggestion.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
