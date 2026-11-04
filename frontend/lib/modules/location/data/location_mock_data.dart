import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Dữ liệu địa chỉ thật cho chế độ mock: 34 tỉnh/thành và 3.321 phường/xã/đặc khu
/// (cùng bộ dữ liệu với backend, xem backend/scripts/locations/build.py), đóng gói
/// trong `assets/data/vn_locations.json`. Đọc một lần rồi giữ trong bộ nhớ.
///
/// Định dạng gọn để file nhỏ (khoảng 210 KB):
/// `{ provinces: [[code, name, shortName]], wards: { provinceCode: [[code, name, shortName, lat, lon]] } }`
class LocationMockData {
  LocationMockData._(this.provinces, this.wardsByProvince);

  static const String assetPath = 'assets/data/vn_locations.json';

  static Future<LocationMockData>? _loading;

  /// Tỉnh/thành theo mã
  final List<AdministrativeUnitModel> provinces;

  /// Phường/xã theo mã tỉnh, mỗi phường có tâm (điểm nằm trong ranh giới)
  final Map<String, List<AdministrativeUnitModel>> wardsByProvince;

  /// Đọc bộ dữ liệu (chỉ đọc file ở lần gọi đầu)
  static Future<LocationMockData> load({AssetBundle? bundle}) =>
      _loading ??= _read(bundle ?? rootBundle).catchError((Object error) {
        _loading = null;
        throw error;
      });

  static Future<LocationMockData> _read(AssetBundle bundle) async {
    final json =
        jsonDecode(await bundle.loadString(assetPath)) as Map<String, dynamic>;
    final provinces = [
      for (final row in json['provinces'] as List)
        AdministrativeUnitModel(
          code: row[0] as String,
          name: row[1] as String,
          shortName: row[2] as String,
          level: AdministrativeLevel.province,
        ),
    ];
    final wards = <String, List<AdministrativeUnitModel>>{
      for (final MapEntry(:key, :value)
          in (json['wards'] as Map<String, dynamic>).entries)
        key: [
          for (final row in value as List)
            AdministrativeUnitModel(
              code: row[0] as String,
              name: row[1] as String,
              shortName: row[2] as String,
              level: AdministrativeLevel.ward,
              parentCode: key,
              center: GeoPoint(
                (row[3] as num).toDouble(),
                (row[4] as num).toDouble(),
              ),
            ),
        ],
    };
    return LocationMockData._(provinces, wards);
  }

  AdministrativeUnitModel? provinceOf(String code) {
    for (final province in provinces) {
      if (province.code == code) return province;
    }
    return null;
  }

  /// Tâm tỉnh/thành: tâm phường có mã nhỏ nhất (phường trung tâm, VD Phường
  /// Ba Đình của Hà Nội), giống backend
  GeoPoint? provinceCenter(String code) =>
      wardsByProvince[code]?.firstOrNull?.center;

  Iterable<AdministrativeUnitModel> get allWards =>
      wardsByProvince.values.expand((wards) => wards);
}
