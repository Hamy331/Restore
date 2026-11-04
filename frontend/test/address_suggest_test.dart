import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/bloc/address_picker/address_picker_cubit.dart';
import 'package:restore/modules/location/models/address_suggestion.dart';
import 'package:restore/modules/location/repositories/address_suggest_repository.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/location/widgets/address_street_field.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/shared/models/geo_point.dart';

AddressPickerCubit _cubit() => AddressPickerCubit(
  repository: MockLocationRepository(latency: Duration.zero),
  locationService: DeviceLocationService(),
  suggestRepository: MockAddressSuggestRepository(latency: Duration.zero),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = MockAddressSuggestRepository(latency: Duration.zero);

  test('gợi ý không dấu, giữ số nhà, ưu tiên phường đang chọn', () async {
    final results = await repository.suggest(
      '12 nguyen',
      provinceCode: '79',
      wardCode: '26743',
    );
    expect(results.first.label, '12 Nguyễn Thái Học');
    expect(results.first.wardCode, '26743');
    expect(results.map((s) => s.label), contains('12 Nguyễn Huệ'));
    expect(results.every((s) => s.provinceCode == '79'), isTrue);
    expect(results.length, lessThanOrEqualTo(AddressSuggestRepository.limit));
  });

  test('lọc theo tỉnh đang chọn', () async {
    final hanoi = await repository.suggest('trang tien', provinceCode: '01');
    expect(hanoi.single.label, 'Tràng Tiền');
    expect(hanoi.single.description, contains('Hà Nội'));
    expect(await repository.suggest('trang tien', provinceCode: '79'), isEmpty);
  });

  test(
    'chọn gợi ý khi chưa chọn phường: điền tỉnh, phường và toạ độ',
    () async {
      final cubit = _cubit();
      await cubit.loadProvinces();
      final suggestion = (await cubit.suggestStreets('12 nguyen hue')).first;
      cubit.changeStreetAddress(suggestion.label);
      await cubit.applySuggestion(suggestion);
      final result = cubit.state.result!;
      expect(result.province.code, '79');
      expect(result.ward.code, '26740');
      expect(result.streetAddress, '12 Nguyễn Huệ');
      expect(result.geoPoint, suggestion.point);
      expect(result.isGeoPointFromDevice, isFalse);
      await cubit.close();
    },
  );

  test('đã chọn phường khác thì giữ phường, không lấy toạ độ gợi ý', () async {
    final cubit = _cubit();
    await cubit.loadProvinces();
    await cubit.selectProvince(
      cubit.state.provinces.firstWhere((p) => p.code == '79'),
    );
    cubit.selectWard(cubit.state.wards.firstWhere((w) => w.code == '26743'));
    await cubit.applySuggestion(
      const AddressSuggestion(
        label: 'Nguyễn Huệ',
        provinceCode: '79',
        wardCode: '26740',
        point: GeoPoint(10.77, 106.70),
      ),
    );
    expect(cubit.state.ward!.code, '26743');
    expect(cubit.state.suggestedGeoPoint, isNull);
    await cubit.close();
  });

  testWidgets('gõ thì hiện gợi ý, chạm vào thì điền vào ô', (tester) async {
    String typed = '';
    AddressSuggestion? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddressStreetField(
            initialValue: '',
            onChanged: (value) => typed = value,
            suggest: (_) async => const [
              AddressSuggestion(
                label: '5 Lê Lợi',
                description: 'Phường Bến Thành, Thành phố Hồ Chí Minh',
                wardCode: '26743',
              ),
            ],
            onSuggestionSelected: (s) => picked = s,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '5 le loi');
    await tester.pump(AddressStreetField.debounce);
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý địa chỉ'), findsOneWidget);
    await tester.tap(find.text('5 Lê Lợi'));
    await tester.pumpAndSettle();
    expect(typed, '5 Lê Lợi');
    expect(picked!.wardCode, '26743');
    expect(find.text('Gợi ý địa chỉ'), findsNothing);
    expect(find.widgetWithText(TextField, '5 Lê Lợi'), findsOneWidget);
  });
}
