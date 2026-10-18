import 'package:equatable/equatable.dart';
import 'package:restore/services/device_location_service.dart';
import '../../models/address_info.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

enum LoadStatus { idle, loading, success, failure }

/// Thông báo hiện ngay trong sheet sau khi định vị mà không ra được địa chỉ
enum LocationNotice {
  /// Toạ độ nằm ngoài Việt Nam (VD máy ảo mặc định ở Mỹ)
  outsideVietnam,

  /// Ở Việt Nam nhưng chưa khớp được phường/xã nào
  outOfCoverage,
}

class AddressPickerState extends Equatable {
  final List<AdministrativeUnitModel> provinces;
  final List<AdministrativeUnitModel> wards;
  final LoadStatus provincesStatus;
  final LoadStatus wardsStatus;
  final AdministrativeUnitModel? province;
  final AdministrativeUnitModel? ward;
  final String streetAddress;

  /// Toạ độ GPS nếu người dùng bấm "Dùng vị trí hiện tại"
  final GeoPoint? deviceGeoPoint;
  final bool isLocating;

  /// Lỗi lần định vị gần nhất, kèm bộ đếm để view hiện thông báo mỗi lần lỗi
  final DeviceLocationError? locateError;
  final int locateErrorCount;

  /// Định vị được nhưng không ra địa chỉ; null khi không có gì cần báo
  final LocationNotice? notice;

  const AddressPickerState({
    this.provinces = const [],
    this.wards = const [],
    this.provincesStatus = LoadStatus.idle,
    this.wardsStatus = LoadStatus.idle,
    this.province,
    this.ward,
    this.streetAddress = '',
    this.deviceGeoPoint,
    this.isLocating = false,
    this.locateError,
    this.locateErrorCount = 0,
    this.notice,
  });

  bool get canConfirm => province != null && ward != null;

  /// Kết quả trả về: ưu tiên toạ độ GPS, nếu không có thì dùng tâm phường/xã
  AddressInfo? get result {
    final province = this.province;
    final ward = this.ward;
    if (province == null || ward == null) return null;
    return AddressInfo(
      province: province,
      ward: ward,
      streetAddress: streetAddress.trim(),
      geoPoint: deviceGeoPoint ?? ward.center,
      isGeoPointFromDevice: deviceGeoPoint != null,
    );
  }

  AddressPickerState copyWith({
    List<AdministrativeUnitModel>? provinces,
    List<AdministrativeUnitModel>? wards,
    LoadStatus? provincesStatus,
    LoadStatus? wardsStatus,
    AdministrativeUnitModel? Function()? province,
    AdministrativeUnitModel? Function()? ward,
    String? streetAddress,
    GeoPoint? Function()? deviceGeoPoint,
    bool? isLocating,
    DeviceLocationError? locateError,
    int? locateErrorCount,
    LocationNotice? Function()? notice,
  }) {
    return AddressPickerState(
      provinces: provinces ?? this.provinces,
      wards: wards ?? this.wards,
      provincesStatus: provincesStatus ?? this.provincesStatus,
      wardsStatus: wardsStatus ?? this.wardsStatus,
      province: province != null ? province() : this.province,
      ward: ward != null ? ward() : this.ward,
      streetAddress: streetAddress ?? this.streetAddress,
      deviceGeoPoint: deviceGeoPoint != null
          ? deviceGeoPoint()
          : this.deviceGeoPoint,
      isLocating: isLocating ?? this.isLocating,
      locateError: locateError ?? this.locateError,
      locateErrorCount: locateErrorCount ?? this.locateErrorCount,
      notice: notice != null ? notice() : this.notice,
    );
  }

  @override
  List<Object?> get props => [
    provinces,
    wards,
    provincesStatus,
    wardsStatus,
    province,
    ward,
    streetAddress,
    deviceGeoPoint,
    isLocating,
    locateError,
    locateErrorCount,
    notice,
  ];
}
