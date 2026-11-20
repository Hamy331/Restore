import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/saved_address_model.dart';

import '../data/location_mock_data.dart';

/// Sổ địa chỉ: địa chỉ đã dùng khi đăng tin để chọn lại, tối đa 5 mỗi người.
/// Backend tự lưu khi đăng / sửa tin, app chỉ đọc, đặt tên và xoá.
abstract class SavedAddressRepository {
  /// Mới dùng gần nhất trước
  Future<List<SavedAddressModel>> getAll();

  /// Đặt tên (null hoặc rỗng = bỏ tên)
  Future<SavedAddressModel> rename(String id, String? label);

  Future<void> delete(String id);
}

/// Dữ liệu mẫu: hai địa chỉ ở TP. Hồ Chí Minh, giữ trong bộ nhớ
class MockSavedAddressRepository implements SavedAddressRepository {
  MockSavedAddressRepository({
    this.latency = const Duration(milliseconds: 250),
    List<SavedAddressModel>? initial,
  }) : _items = initial;

  final Duration latency;
  List<SavedAddressModel>? _items;

  Future<List<SavedAddressModel>> _load() async {
    final items = _items;
    if (items != null) return items;
    final data = await LocationMockData.load();
    final province = data.provinces.firstWhere((unit) => unit.code == '79');
    final wards = data.wardsByProvince['79'] ?? const [];
    SavedAddressModel sample(
      String id,
      String wardCode,
      String street,
      String? label,
      int daysAgo,
    ) {
      final ward = wards.firstWhere((unit) => unit.code == wardCode);
      return SavedAddressModel(
        id: id,
        label: label,
        province: province,
        ward: ward,
        streetAddress: street,
        geoPoint: ward.center!,
        lastUsedAt: DateTime.now().subtract(Duration(days: daysAgo)),
      );
    }

    return _items = [
      sample('mock-address-1', '26740', '12 Nguyễn Huệ', 'Nhà', 1),
      sample('mock-address-2', '25747', '45 Yersin', null, 9),
    ];
  }

  @override
  Future<List<SavedAddressModel>> getAll() async {
    await Future<void>.delayed(latency);
    return List.unmodifiable(await _load());
  }

  @override
  Future<SavedAddressModel> rename(String id, String? label) async {
    await Future<void>.delayed(latency);
    final items = await _load();
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Address not found');
    final value = label?.trim();
    final updated = items[index].copyWith(
      label: () => value == null || value.isEmpty ? null : value,
    );
    _items = [...items]..[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(latency);
    final items = await _load();
    _items = items.where((item) => item.id != id).toList();
  }
}

/// `GET /users/me/addresses` → `{ data: [SavedAddress] }`,
/// `PATCH /users/me/addresses/:id { label }`, `DELETE /users/me/addresses/:id`
class ApiSavedAddressRepository implements SavedAddressRepository {
  ApiSavedAddressRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<SavedAddressModel>> getAll() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/users/me/addresses',
    );
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data)
        SavedAddressModel.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  @override
  Future<SavedAddressModel> rename(String id, String? label) async {
    final value = label?.trim();
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/users/me/addresses/$id',
      data: {'label': value == null || value.isEmpty ? null : value},
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return SavedAddressModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> delete(String id) =>
      _apiClient.dio.delete<void>('/users/me/addresses/$id');
}
