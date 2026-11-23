import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/shared/models/geo_point.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/location/utils/listing_area.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/filter_popover.dart';

/// Tỉnh / thành chọn nhanh (tên → mã tỉnh): 5 thành phố trực thuộc trung
/// ương theo danh sách 34 tỉnh mới
const quickProvinceCodes = {
  'TP. Hồ Chí Minh': '79',
  'Hà Nội': '01',
  'Đà Nẵng': '48',
  'Hải Phòng': '31',
  'Cần Thơ': '92',
};

/// Bảng "Khu vực" (bottom sheet trên điện thoại, popover dưới
/// [anchor] trên màn rộng): tìm quanh vị trí hiện tại, hoặc chọn tỉnh / thành
/// (có chip chọn nhanh) rồi phường / xã; chân bảng Xoá lọc / Áp dụng. Chỉ đổi
/// khu vực của bộ lọc trên trang. Trả bộ lọc mới, null nếu đóng bảng.
Future<ListingFilter?> showAreaFilterPanel(
  BuildContext anchor,
  ListingFilter filter, {
  LocationRepository? repository,
}) => showFilterPopover<ListingFilter>(
  anchor,
  width: 380,
  builder: (_) => _AreaPanel(
    filter: filter,
    repository:
        repository ??
        (AppEnvironment.useMockData
            ? MockLocationRepository()
            : ApiLocationRepository()),
  ),
);

/// Chọn khu vực bằng cùng bảng "Khu vực" (thay trang chọn khu vực cũ): trả
/// [AreaPickResult] như trang cũ để nơi gọi giữ nguyên cách xử lý.
/// - Áp dụng: khu vực đã chọn (tỉnh / thành hoặc phường / xã)
/// - Xoá lọc: toàn quốc (chỉ có khi [allowNationwide])
/// - Dùng vị trí hiện tại: [AreaPickResult.myLocation], nơi gọi tự định vị
/// Null nếu đóng bảng.
Future<AreaPickResult?> showAreaPicker(
  BuildContext anchor, {
  AreaOption? current,
  bool allowNationwide = true,
  LocationRepository? repository,
}) => showFilterPopover<AreaPickResult>(
  anchor,
  width: 380,
  builder: (_) => _AreaPanel(
    filter: const ListingFilter().withAreaOption(current),
    picker: true,
    allowNationwide: allowNationwide,
    repository:
        repository ??
        (AppEnvironment.useMockData
            ? MockLocationRepository()
            : ApiLocationRepository()),
  ),
);

/// Một đơn vị hành chính đã chọn ([center] để làm khu vực của cả app)
typedef _Unit = ({String code, String name, GeoPoint? center});

enum _Step { main, provinces, wards }

class _AreaPanel extends StatefulWidget {
  const _AreaPanel({
    required this.filter,
    required this.repository,
    this.picker = false,
    this.allowNationwide = true,
  });

  final ListingFilter filter;
  final LocationRepository repository;

  /// Chọn khu vực (trả [AreaPickResult]) thay vì đổi bộ lọc của trang
  final bool picker;
  final bool allowNationwide;

  @override
  State<_AreaPanel> createState() => _AreaPanelState();
}

class _AreaPanelState extends State<_AreaPanel> {
  var _step = _Step.main;
  late _Unit? _province = widget.filter.provinceCode == null
      ? null
      : (
          code: widget.filter.provinceCode!,
          name: widget.filter.areaLabel ?? widget.filter.provinceCode!,
          center: null,
        );
  late _Unit? _ward = widget.filter.wardCode == null
      ? null
      : (
          code: widget.filter.wardCode!,
          name: widget.filter.areaLabel ?? widget.filter.wardCode!,
          center: null,
        );
  late final _provinces = widget.repository.getProvinces();
  Future<List<AdministrativeUnitModel>>? _wards;
  String _query = '';
  bool _locating = false;

  String _t(String vi, String en) =>
      Localizations.localeOf(context).languageCode == 'vi' ? vi : en;

  void _open(_Step step) => setState(() {
    _step = step;
    _query = '';
    final province = _province;
    if (step == _Step.wards && province != null) {
      _wards = widget.repository.getWards(province.code);
    }
  });

  void _selectProvince(_Unit? province) => setState(() {
    _province = province;
    _ward = null;
    _step = _Step.main;
  });

  Future<void> _apply() async {
    final ward = _ward;
    final province = _province;
    if (widget.picker) {
      final area = await _pickedArea();
      if (!mounted) return;
      if (area != null) {
        Navigator.of(context).pop(AreaPickResult.area(area));
      } else if (ward == null && province == null) {
        // Chưa chọn gì mà bấm Áp dụng: như Xoá lọc
        Navigator.of(context).pop(
          widget.allowNationwide ? const AreaPickResult.nationwide() : null,
        );
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Chưa tải được vị trí của khu vực này, thử lại sau.',
                'Could not load this area, please try again.',
              ),
            ),
          ),
        );
      }
      return;
    }
    Navigator.of(context).pop(
      ward != null
          ? widget.filter.withArea(ward.code, isWard: true, label: ward.name)
          : widget.filter.withArea(province?.code, label: province?.name),
    );
  }

  /// Khu vực đã chọn thành [AreaOption]; toạ độ lấy từ danh sách tỉnh nếu
  /// chọn bằng chip (chip không kèm toạ độ). Null là chưa chọn gì.
  Future<AreaOption?> _pickedArea() async {
    final ward = _ward, province = _province;
    final unit = ward ?? province;
    if (unit == null) return null;
    var center = unit.center;
    // Danh sách tỉnh không kèm toạ độ: lấy tâm phường đầu tiên của tỉnh như
    // backend và như khi định vị
    if (center == null && province != null) {
      try {
        final wards = await widget.repository.getWards(province.code);
        center = wards.firstOrNull?.center;
      } catch (_) {}
    }
    // Không có toạ độ thì không đổi được khu vực (tính khoảng cách cần tâm)
    if (center == null) return null;
    return AreaOption(
      code: unit.code,
      name: unit.name,
      level: ward != null
          ? AdministrativeLevel.ward
          : AdministrativeLevel.province,
      center: center,
      parentName: ward != null ? province?.name : null,
    );
  }

  /// "Tìm kiếm quanh bạn": khu vực theo vị trí hiện tại (như nút Gần tôi)
  Future<void> _useMyLocation() async {
    if (widget.picker) {
      Navigator.of(context).pop(const AreaPickResult.myLocation());
      return;
    }
    final userArea = context.read<UserAreaCubit>();
    setState(() => _locating = true);
    await userArea.locate();
    if (!mounted) return;
    setState(() => _locating = false);
    final area = userArea.state.area;
    if (area != null) {
      Navigator.of(context).pop(widget.filter.withAreaOption(area));
    }
  }

  @override
  Widget build(BuildContext context) => switch (_step) {
    _Step.main => _main(),
    _Step.provinces => _list(
      title: _t('Chọn tỉnh thành', 'Choose a province'),
      searchLabel: _t('tỉnh thành', 'province'),
      units: _provinces,
      selected: _province?.code,
      onPick: _selectProvince,
    ),
    _Step.wards => _list(
      title: _t('Chọn phường, xã', 'Choose a ward'),
      searchLabel: _t('phường, xã', 'ward'),
      units: _wards!,
      selected: _ward?.code,
      onPick: (ward) => setState(() {
        _ward = ward;
        _step = _Step.main;
      }),
    ),
  };

  Widget _main() {
    final province = _province;
    final ward = _ward;
    return FilterPanel(
      title: _t('Khu vực', 'Area'),
      onClear: !widget.picker
          ? () => Navigator.of(context).pop(widget.filter.withArea(null))
          : widget.allowNationwide
          ? () => Navigator.of(context).pop(const AreaPickResult.nationwide())
          : null,
      onApply: _apply,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        children: [
          _SectionTitle(
            icon: Icons.my_location,
            title: _t('Tìm kiếm quanh bạn', 'Search near you'),
          ),
          _PickRow(
            label: _t(
              'Dùng vị trí hiện tại của bạn',
              'Use my current location',
            ),
            loading: _locating,
            onTap: _locating ? null : _useMyLocation,
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            icon: Icons.location_city_outlined,
            title: _t('Tìm theo khu vực', 'Search by area'),
          ),
          _PickRow(
            label: province?.name ?? _t('Chọn tỉnh thành', 'Choose a province'),
            selected: province != null,
            onTap: () => _open(_Step.provinces),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: name, value: code)
                  in quickProvinceCodes.entries)
                ChoiceChip(
                  label: Text(name),
                  selected: province?.code == code,
                  showCheckmark: false,
                  selectedColor: AppColors.actionPrimary,
                  labelStyle: TextStyle(
                    color: province?.code == code
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  side: const BorderSide(color: AppColors.border),
                  shape: const StadiumBorder(),
                  onSelected: (on) => _selectProvince(
                    on ? (code: code, name: name, center: null) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _PickRow(
            label: ward?.name ?? _t('Chọn phường, xã', 'Choose a ward'),
            selected: ward != null,
            // Phường / xã chọn sau khi đã có tỉnh / thành
            onTap: province == null ? null : () => _open(_Step.wards),
          ),
        ],
      ),
    );
  }

  /// Danh sách tỉnh / thành hoặc phường / xã, có ô tìm (không dấu vẫn ra)
  Widget _list({
    required String title,
    required String searchLabel,
    required Future<List<AdministrativeUnitModel>> units,
    required String? selected,
    required ValueChanged<_Unit> onPick,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return FilterPanel(
      title: title,
      onBack: () => setState(() => _step = _Step.main),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (text) => setState(() => _query = text),
              decoration: InputDecoration(
                hintText: l10n.filterSearchHint(searchLabel),
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Flexible(
            child: FutureBuilder<List<AdministrativeUnitModel>>(
              future: units,
              builder: (context, snapshot) {
                final items = snapshot.data;
                if (items == null) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: snapshot.hasError
                          ? Text(
                              _t('Không tải được danh sách', 'Could not load'),
                            )
                          : const CircularProgressIndicator(),
                    ),
                  );
                }
                final shown = [
                  for (final item in items)
                    if (_query.trim().isEmpty ||
                        VietnameseText.matches(item.name, _query))
                      item,
                ];
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final item = shown[index];
                    final isSelected = item.code == selected;
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.actionPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      onTap: () => onPick((
                        code: item.code,
                        name: item.shortName ?? item.name,
                        center: item.center,
                      )),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Ô chọn viền xám có mũi tên ">" (mờ đi khi chưa dùng được)
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || loading;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (loading)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
