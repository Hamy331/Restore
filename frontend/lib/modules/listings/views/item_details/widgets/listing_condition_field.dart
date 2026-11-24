import 'package:flutter/material.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../../../repositories/category_repository.dart';
import 'listing_form_widgets.dart';

/// Ô "Tình trạng": chạm để mở sheet chọn. Xe cộ dùng thang tình trạng riêng
/// (xe mới, xe lướt, cần sửa...), cùng giá trị API với đồ dùng khác.
class ListingConditionField extends StatefulWidget {
  const ListingConditionField({
    super.key,
    required this.selected,
    required this.vehicle,
    required this.onSelected,
    this.errorText,
    this.loadActive,
  });

  final ListingCondition? selected;
  final bool vehicle;
  final ValueChanged<ListingCondition> onSelected;
  final String? errorText;

  /// Tình trạng admin còn cho dùng (mặc định gọi /catalog/conditions)
  final Future<Set<ListingCondition>> Function()? loadActive;

  @override
  State<ListingConditionField> createState() => _ListingConditionFieldState();
}

class _ListingConditionFieldState extends State<ListingConditionField> {
  late Future<Set<ListingCondition>> _active = _load();

  Future<Set<ListingCondition>> _load() =>
      widget.loadActive?.call() ??
      (AppEnvironment.useMockData
          ? Future.value(ListingCondition.values.toSet())
          : ApiCategoryRepository().getActiveConditions().then(
              (rows) => rows.keys.toSet(),
            ));

  Future<void> _open() async {
    Set<ListingCondition> active;
    try {
      active = await _active;
    } catch (_) {
      // Không tải được danh sách: vẫn cho chọn, backend kiểm tra lại
      _active = _load();
      active = ListingCondition.values.toSet();
    }
    if (!mounted) return;
    final options = [
      for (final value in ListingCondition.values)
        if (active.contains(value) || value == widget.selected) value,
    ];
    final chosen = await showListingConditionSheet(
      context,
      options: options,
      selected: widget.selected,
      vehicle: widget.vehicle,
    );
    if (chosen != null) widget.onSelected(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListingLabeledField(
      label: l10n.conditionLabel,
      errorText: widget.errorText,
      child: ListingSelectBox(
        placeholder: l10n.conditionChoose,
        value: widget.selected?.labelFor(l10n, vehicle: widget.vehicle),
        hasError: widget.errorText != null,
        onTap: _open,
      ),
    );
  }
}

/// Sheet chọn tình trạng: tiêu đề giữa, nút X, mỗi dòng có mô tả và vòng
/// chọn. Chọn xong thì đóng và trả về tình trạng đã chọn.
Future<ListingCondition?> showListingConditionSheet(
  BuildContext context, {
  required List<ListingCondition> options,
  required ListingCondition? selected,
  required bool vehicle,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<ListingCondition>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  l10n.conditionLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: const Icon(AppIcons.close, size: 26),
                    tooltip: MaterialLocalizations.of(
                      sheetContext,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                for (final option in options)
                  _ConditionOption(
                    title: option.labelFor(l10n, vehicle: vehicle),
                    description: option.descriptionFor(l10n, vehicle: vehicle),
                    selected: option == selected,
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ConditionOption extends StatelessWidget {
  const _ConditionOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: ListingFormStyle.subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ListingRadioMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}
