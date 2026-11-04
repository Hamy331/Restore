import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_state.dart';
import 'package:restore/modules/location/data/location_mock_data.dart';
import 'package:restore/modules/location/repositories/area_search_repository.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/shared/models/geo_point.dart';

/// GPS giả: trả [point] hoặc ném [error]
class _FakeLocationService extends DeviceLocationService {
  _FakeLocationService({this.point, this.error});

  final GeoPoint? point;
  final DeviceLocationError? error;

  @override
  Future<GeoPoint> getCurrentPosition() async {
    if (error case final error?) throw DeviceLocationException(error);
    return point!;
  }
}

UserAreaCubit _cubit({GeoPoint? point, DeviceLocationError? error}) =>
    UserAreaCubit(
      locationRepository: MockLocationRepository(latency: Duration.zero),
      locationService: _FakeLocationService(point: point, error: error),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bộ dữ liệu đóng gói có đủ 34 tỉnh và 3.321 phường/xã', () async {
    final data = await LocationMockData.load();
    expect(data.provinces, hasLength(34));
    expect(data.allWards, hasLength(3321));
    expect(data.wardsByProvince['79'], hasLength(168));
    expect(data.provinceOf('79')!.displayName, 'Hồ Chí Minh');
    expect(data.allWards.every((ward) => ward.center != null), isTrue);
  });

  test('mở app ở TP.HCM: hiện "Hồ Chí Minh"', () async {
    final cubit = _cubit(point: const GeoPoint(10.7769, 106.7009));
    await cubit.locate();
    expect(cubit.state.status, UserAreaStatus.ready);
    expect(cubit.state.area!.code, '79');
    expect(cubit.state.area!.displayName, 'Hồ Chí Minh');
    await cubit.close();
  });

  test('ở Hà Nội: hiện "Hà Nội"', () async {
    final cubit = _cubit(point: const GeoPoint(21.0285, 105.8542));
    await cubit.locate();
    expect(cubit.state.area!.displayName, 'Hà Nội');
    await cubit.close();
  });

  test(
    'từ chối quyền, tắt định vị hoặc GPS ngoài Việt Nam: Toàn quốc',
    () async {
      for (final cubit in [
        _cubit(error: DeviceLocationError.permissionDenied),
        _cubit(error: DeviceLocationError.serviceDisabled),
        _cubit(error: DeviceLocationError.unavailable),
        _cubit(point: const GeoPoint(37.42, -122.08)), // máy ảo mặc định ở Mỹ
      ]) {
        await cubit.locate();
        expect(cubit.state.status, UserAreaStatus.nationwide);
        await cubit.close();
      }
    },
  );

  test('tự chọn khu vực thì giữ lựa chọn đó', () async {
    final areas = await MockAreaSearchRepository(
      latency: Duration.zero,
    ).search('da nang');
    final cubit = _cubit(point: const GeoPoint(10.7769, 106.7009));
    cubit.select(areas.first);
    expect(cubit.state.isManual, isTrue);
    expect(cubit.state.area!.displayName, 'Đà Nẵng');
    cubit.selectNationwide();
    expect(cubit.state.status, UserAreaStatus.nationwide);
    await cubit.close();
  });

  test('tìm khu vực không dấu trên dữ liệu thật', () async {
    final repo = MockAreaSearchRepository(latency: Duration.zero);
    expect((await repo.search('ho chi minh')).first.code, '79');
    final dalat = await repo.search('da lat');
    expect(dalat.first.parentName, 'Tỉnh Lâm Đồng');
    expect((await repo.search('sai gon')).first.name, 'Phường Sài Gòn');
  });
}
