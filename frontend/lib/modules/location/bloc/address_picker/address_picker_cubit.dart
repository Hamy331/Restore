import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/services/device_location_service.dart';
import '../../data/vietnam_bounds.dart';
import '../../models/address_info.dart';
import '../../models/address_suggestion.dart';
import '../../repositories/address_suggest_repository.dart';
import '../../repositories/saved_address_repository.dart';
import 'package:restore/data/models/saved_address_model.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import '../../repositories/location_repository.dart';
import 'address_picker_state.dart';

class AddressPickerCubit extends Cubit<AddressPickerState> {
  AddressPickerCubit({
    required LocationRepository repository,
    required DeviceLocationService locationService,
    AddressSuggestRepository? suggestRepository,
    SavedAddressRepository? savedRepository,
    AddressInfo? initial,
  }) : _repository = repository,
       _locationService = locationService,
       _suggestRepository = suggestRepository,
       _savedRepository = savedRepository,
       super(
         AddressPickerState(
           province: initial?.province,
           ward: initial?.ward,
           streetAddress: initial?.streetAddress ?? '',
           deviceGeoPoint: initial?.isGeoPointFromDevice == true
               ? initial?.geoPoint
               : null,
           suggestedGeoPoint:
               initial != null &&
                   !initial.isGeoPointFromDevice &&
                   initial.geoPoint != initial.ward.center
               ? initial.geoPoint
               : null,
         ),
       );

  final LocationRepository _repository;
  final DeviceLocationService _locationService;
  final AddressSuggestRepository? _suggestRepository;
  final SavedAddressRepository? _savedRepository;

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

  /// Tải sổ địa chỉ; lỗi (VD chưa đăng nhập) thì chỉ ẩn mục này
  Future<void> loadSavedAddresses() async {
    final repository = _savedRepository;
    if (repository == null) return;
    emit(state.copyWith(savedStatus: LoadStatus.loading));
    try {
      final items = await repository.getAll();
      emit(
        state.copyWith(savedAddresses: items, savedStatus: LoadStatus.success),
      );
    } catch (_) {
      emit(state.copyWith(savedStatus: LoadStatus.failure));
    }
  }

  /// Địa chỉ trả về khi chọn một địa chỉ đã lưu
  AddressInfo addressFromSaved(SavedAddressModel saved) => AddressInfo(
    province: saved.province,
    ward: saved.ward,
    streetAddress: saved.streetAddress,
    geoPoint: saved.geoPoint,
    isGeoPointFromDevice: saved.isGeoPointFromDevice,
  );

  /// Đặt / bỏ tên địa chỉ đã lưu; false khi lỗi
  Future<bool> renameSaved(SavedAddressModel saved, String? label) async {
    final repository = _savedRepository;
    if (repository == null) return false;
    try {
      final updated = await repository.rename(saved.id, label);
      emit(
        state.copyWith(
          savedAddresses: [
            for (final item in state.savedAddresses)
              item.id == updated.id ? updated : item,
          ],
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Xoá địa chỉ đã lưu (ẩn ngay, lỗi thì hiện lại); false khi lỗi
  Future<bool> deleteSaved(SavedAddressModel saved) async {
    final repository = _savedRepository;
    if (repository == null) return false;
    final before = state.savedAddresses;
    emit(
      state.copyWith(
        savedAddresses: [
          for (final item in before)
            if (item.id != saved.id) item,
        ],
      ),
    );
    try {
      await repository.delete(saved.id);
      return true;
    } catch (_) {
      emit(state.copyWith(savedAddresses: before));
      return false;
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
        suggestedGeoPoint: () => null,
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
        suggestedGeoPoint: () => null,
        notice: () => null,
      ),
    );
  }

  /// Gõ lại địa chỉ thì toạ độ của gợi ý đã chọn trước đó không còn đúng
  void changeStreetAddress(String value) =>
      emit(state.copyWith(streetAddress: value, suggestedGeoPoint: () => null));

  /// Gợi ý số nhà, tên đường quanh tỉnh/phường đang chọn
  Future<List<AddressSuggestion>> suggestStreets(String query) async {
    final repository = _suggestRepository;
    if (repository == null) return const [];
    return repository.suggest(
      query,
      provinceCode: state.province?.code,
      wardCode: state.ward?.code,
    );
  }

  /// Chọn một gợi ý: ô địa chỉ đã điền sẵn qua [changeStreetAddress]. Chưa
  /// chọn phường/xã thì chọn luôn tỉnh và phường của gợi ý; khớp phường thì
  /// lấy toạ độ của gợi ý.
  Future<void> applySuggestion(AddressSuggestion suggestion) async {
    final provinceCode = suggestion.provinceCode;
    final wardCode = suggestion.wardCode;
    if (state.ward == null && provinceCode != null && wardCode != null) {
      final province = state.provinces
          .where((unit) => unit.code == provinceCode)
          .firstOrNull;
      if (province != null) {
        if (province.code != state.province?.code) {
          await selectProvince(province);
        } else if (state.wardsStatus != LoadStatus.success) {
          await _loadWards(province.code);
        }
        final ward = state.wards
            .where((unit) => unit.code == wardCode)
            .firstOrNull;
        if (ward != null && state.ward == null) selectWard(ward);
      }
    }
    final point = suggestion.point;
    if (point != null &&
        state.ward != null &&
        state.ward!.code == wardCode &&
        state.deviceGeoPoint == null) {
      emit(state.copyWith(suggestedGeoPoint: () => point));
    }
  }

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
