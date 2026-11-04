import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/shared/models/geo_point.dart';

import '../../models/area_option.dart';
import '../../repositories/location_repository.dart';
import 'user_area_state.dart';

/// Khu vực của người dùng cho cả app.
///
/// Mở app: xin quyền vị trí, đổi GPS thành tỉnh/thành (VD người ở TP.HCM thấy
/// "Hồ Chí Minh"). Từ chối quyền, tắt định vị, hết thời gian chờ hay GPS ngoài
/// Việt Nam thì hiện "Toàn quốc". Người dùng có thể tự chọn khu vực khác.
class UserAreaCubit extends Cubit<UserAreaState> with SafeEmit<UserAreaState> {
  UserAreaCubit({
    required LocationRepository locationRepository,
    DeviceLocationService? locationService,
  }) : _locationRepository = locationRepository,
       _locationService = locationService ?? DeviceLocationService(),
       super(const UserAreaState());

  final LocationRepository _locationRepository;
  final DeviceLocationService _locationService;

  /// Định vị và lấy tỉnh/thành chứa vị trí đó
  Future<void> locate() async {
    emit(const UserAreaState());
    try {
      final point = await _locationService.getCurrentPosition();
      final address = await _locationRepository.reverseGeocode(point);
      // Người dùng đã tự chọn trong lúc chờ GPS thì giữ lựa chọn đó
      if (state.isManual) return;
      final province = address?.province;
      if (province == null) {
        emit(const UserAreaState.nationwide());
        return;
      }
      emit(
        UserAreaState(
          status: UserAreaStatus.ready,
          area: await _provinceArea(province, fallbackCenter: point),
        ),
      );
    } catch (_) {
      // Không quyền, tắt định vị, mất mạng...: tạm hiện toàn quốc
      if (!state.isManual) emit(const UserAreaState.nationwide());
    }
  }

  /// Người dùng tự chọn khu vực trên trang chọn khu vực
  void select(AreaOption area) => emit(
    UserAreaState(status: UserAreaStatus.ready, area: area, isManual: true),
  );

  void selectNationwide() =>
      emit(const UserAreaState.nationwide(isManual: true));

  /// Tỉnh dạng AreaOption; tâm lấy như backend (tâm phường trung tâm), không có
  /// thì dùng chính vị trí GPS
  Future<AreaOption> _provinceArea(
    AdministrativeUnitModel province, {
    required GeoPoint fallbackCenter,
  }) async {
    var center = fallbackCenter;
    try {
      final wards = await _locationRepository.getWards(province.code);
      center = wards.firstOrNull?.center ?? center;
    } catch (_) {
      // Giữ vị trí GPS
    }
    return AreaOption(
      code: province.code,
      name: province.name,
      shortName: province.shortName ?? _shortNameOf(province.name),
      level: AdministrativeLevel.province,
      center: center,
    );
  }

  /// API cũ không trả shortName: bỏ tiền tố cấp ("Thành phố ", "Tỉnh ", "TP. ")
  static String _shortNameOf(String name) =>
      name.replaceFirst(RegExp(r'^(Thành phố|Tỉnh|TP\.)\s+'), '');
}
