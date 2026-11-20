import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/modules/location/widgets/address_picker_sheet.dart';
import 'package:restore/data/models/saved_address_model.dart';
import 'package:restore/modules/location/bloc/address_picker/address_picker_cubit.dart';
import 'package:restore/modules/location/bloc/address_picker/address_picker_state.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/location/repositories/saved_address_repository.dart';
import 'package:restore/services/device_location_service.dart';

AddressPickerCubit _cubit(SavedAddressRepository repository) =>
    AddressPickerCubit(
      repository: MockLocationRepository(latency: Duration.zero),
      locationService: DeviceLocationService(),
      savedRepository: repository,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('đọc địa chỉ đã lưu từ JSON của API', () {
    final saved = SavedAddressModel.fromJson({
      'id': 'a1',
      'label': 'Nhà',
      'provinceCode': '79',
      'wardCode': '26740',
      'province': {
        'code': '79',
        'name': 'Thành phố Hồ Chí Minh',
        'level': 'province',
      },
      'ward': {
        'code': '26740',
        'name': 'Phường Sài Gòn',
        'level': 'ward',
        'parentCode': '79',
      },
      'streetAddress': '12 Nguyễn Huệ',
      'latitude': 10.77,
      'longitude': 106.7,
      'geoSource': 'device',
      'lastUsedAt': '2026-11-20T10:00:00.000Z',
    });
    expect(
      saved.fullLabel,
      '12 Nguyễn Huệ, Phường Sài Gòn, Thành phố Hồ Chí Minh',
    );
    expect(saved.isGeoPointFromDevice, isTrue);
    expect(saved.geoPoint.latitude, 10.77);
  });

  test(
    'tải sổ địa chỉ, chọn lại thì ra đủ tỉnh, phường, số nhà, toạ độ',
    () async {
      final cubit = _cubit(MockSavedAddressRepository(latency: Duration.zero));
      await cubit.loadSavedAddresses();
      expect(cubit.state.savedStatus, LoadStatus.success);
      expect(cubit.state.savedAddresses.length, 2);
      final saved = cubit.state.savedAddresses.first;
      final address = cubit.addressFromSaved(saved);
      expect(address.province.code, '79');
      expect(address.ward.code, '26740');
      expect(address.streetAddress, '12 Nguyễn Huệ');
      expect(address.geoPoint, saved.geoPoint);
      await cubit.close();
    },
  );

  test('đặt tên, bỏ tên và xoá địa chỉ đã lưu', () async {
    final repository = MockSavedAddressRepository(latency: Duration.zero);
    final cubit = _cubit(repository);
    await cubit.loadSavedAddresses();
    final second = cubit.state.savedAddresses[1];
    expect(await cubit.renameSaved(second, ' Cửa hàng '), isTrue);
    expect(cubit.state.savedAddresses[1].label, 'Cửa hàng');
    expect(await cubit.renameSaved(second, ''), isTrue);
    expect(cubit.state.savedAddresses[1].label, isNull);
    expect(await cubit.deleteSaved(second), isTrue);
    expect(cubit.state.savedAddresses.map((a) => a.id), ['mock-address-1']);
    expect((await repository.getAll()).length, 1);
    await cubit.close();
  });

  test('lỗi tải (VD chưa đăng nhập) thì không có địa chỉ nào', () async {
    final cubit = _cubit(_FailingRepository());
    await cubit.loadSavedAddresses();
    expect(cubit.state.savedStatus, LoadStatus.failure);
    expect(cubit.state.savedAddresses, isEmpty);
    await cubit.close();
  });

  testWidgets('sheet địa chỉ: chạm địa chỉ đã lưu thì trả về luôn', (
    tester,
  ) async {
    AddressInfo? result;
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LocationRepository>(
            create: (_) => MockLocationRepository(latency: Duration.zero),
          ),
          RepositoryProvider(create: (_) => DeviceLocationService()),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showAddressPickerSheet(
                  context,
                  savedRepository: MockSavedAddressRepository(
                    latency: Duration.zero,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Dữ liệu tỉnh/phường mẫu đọc từ asset: cần chờ thật vài vòng
    for (var i = 0; i < 10 && find.text('Nhà').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(find.text('Địa chỉ đã lưu'), findsOneWidget);
    expect(find.text('Nhà'), findsOneWidget);
    expect(find.text('45 Yersin'), findsOneWidget);
    await tester.tap(find.text('Nhà'));
    await tester.pumpAndSettle();
    expect(result?.ward.code, '26740');
    expect(result?.streetAddress, '12 Nguyễn Huệ');
  });
}

class _FailingRepository implements SavedAddressRepository {
  @override
  Future<List<SavedAddressModel>> getAll() async => throw Exception('401');
  @override
  Future<SavedAddressModel> rename(String id, String? label) async =>
      throw Exception('401');
  @override
  Future<void> delete(String id) async => throw Exception('401');
}
