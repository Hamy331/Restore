import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/services/device_location_service.dart';
import '../../data/vietnam_bounds.dart';
import '../../models/address_info.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import '../../repositories/location_repository.dart';
import 'address_picker_state.dart';

class AddressPickerCubit extends Cubit<AddressPickerState> {
  AddressPickerCubit({
    required LocationRepository repository,
    required DeviceLocationService locationService,
    AddressInfo? initial,
  }) : _repository = repository,
       _locationService = locationService,
       super(
         AddressPickerState(
           province: initial?.province,
           ward: initial?.ward,
           streetAddress: initial?.streetAddress ?? '',
           deviceGeoPoint: initial?.isGeoPointFromDevice == true
               ? initial?.geoPoint
               : null,
         ),
       );

  final LocationRepository _repository;
  final DeviceLocationService _locationService;

  /// Sheet địa chỉ đóng cubit ngay khi người dùng đóng sheet, trong khi các
  /// việc bất đồng bộ (lấy GPS, tải phường/xã) có thể xong sau đó. Bỏ qua các
  /// lần emit muộn thay vì ném lỗi "Cannot emit new states after calling close".
  @override
  void emit(AddressPickerState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> loadProvinces() async {
    emit(state.copyWith(provincesStatus: LoadStatus.loading));
    try {
      final provinces = await _repository.getProvinces();
      emit(
        state.copyWith(
          provinces: provinces,
          provincesStatus: LoadStatus.success,
        ),
      );
      final province = state.province;
      if (province != null) await _loadWards(province.code);
    } catch (_) {
      emit(state.copyWith(provincesStatus: LoadStatus.failure));
    }
  }

  Future<void> selectProvince(AdministrativeUnitModel province) async {
    if (province.code == state.province?.code) return;
    // Đổi tỉnh thì phường cũ và toạ độ GPS không còn đúng
    emit(
      state.copyWith(
        province: () => province,
        ward: () => null,
        wards: const [],
        deviceGeoPoint: () => null,
        notice: () => null,
      ),
    );
    await _loadWards(province.code);
  }

  void selectWard(AdministrativeUnitModel ward) {
    if (ward.code == state.ward?.code) return;
    emit(
      state.copyWith(
        ward: () => ward,
        deviceGeoPoint: () => null,
        notice: () => null,
      ),
    );
  }

  void changeStreetAddress(String value) =>
      emit(state.copyWith(streetAddress: value));

  Future<void> retryWards() async {
    final province = state.province;
    if (province != null) await _loadWards(province.code);
  }

  Future<void> useCurrentLocation() async {
    if (state.isLocating) return;
    emit(state.copyWith(isLocating: true, notice: () => null));
    try {
      final point = await _locationService.getCurrentPosition();
      final address = await _repository.reverseGeocode(point);
      if (address == null) {
        emit(
          state.copyWith(
            isLocating: false,
            notice: () => VietnamBounds.contains(point)
                ? LocationNotice.outOfCoverage
                : LocationNotice.outsideVietnam,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isLocating: false,
          province: () => address.province,
          ward: () => address.ward,
          deviceGeoPoint: () => point,
        ),
      );
      await _loadWards(address.province.code);
    } on DeviceLocationException catch (exception) {
      _emitLocateError(exception.error);
    } catch (_) {
      _emitLocateError(DeviceLocationError.unavailable);
    }
  }

  void dismissNotice() => emit(state.copyWith(notice: () => null));

  Future<void> openAppSettings() => _locationService.openAppSettings();

  void _emitLocateError(DeviceLocationError error) {
    emit(
      state.copyWith(
        isLocating: false,
        locateError: error,
        locateErrorCount: state.locateErrorCount + 1,
      ),
    );
  }

  Future<void> _loadWards(String provinceCode) async {
    emit(state.copyWith(wardsStatus: LoadStatus.loading));
    try {
      final wards = await _repository.getWards(provinceCode);
      // Người dùng có thể đã đổi tỉnh trong lúc chờ
      if (state.province?.code != provinceCode) return;
      emit(state.copyWith(wards: wards, wardsStatus: LoadStatus.success));
    } catch (_) {
      if (state.province?.code != provinceCode) return;
      emit(state.copyWith(wardsStatus: LoadStatus.failure));
    }
  }
}
