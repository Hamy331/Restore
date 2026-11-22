import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';

import 'app_filter_bar.dart';
import 'listing_filter_section.dart';

/// Chọn danh mục con (hoặc "Tất cả") của danh mục đang lọc: hàng
/// "Danh mục" trong sheet Bộ lọc
class ListingFilterSubcategorySection extends StatelessWidget {
  final CategoryModel category;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const ListingFilterSubcategorySection({
    super.key,
    required this.category,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListingFilterSection(
      title: l10n.listingFilterSubcategory(category.name.of(context)),
      child: ListingFilterChipWrap(
        children: [
          AppFilterChip(
            label: l10n.listingFilterAllSubcategories,
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final item in category.subcategories)
            AppFilterChip(
              label: item.name.of(context),
              selected: item.id == selectedId,
              // Bấm lại danh mục con đang chọn thì bỏ chọn
              onTap: () => onSelected(item.id == selectedId ? null : item.id),
            ),
        ],
      ),
    );
  }
}

/// Một bộ lọc thuộc tính của danh mục (con), dựng theo kiểu bộ lọc:
/// - single: chip chọn một (Loại xe, Nhiên liệu...)
/// - multi: chip chọn nhiều (Dung lượng, RAM...)
/// - list: chọn một trong danh sách dài có ô tìm (Hãng, Màu, Giống): một dòng
///   bấm để mở danh sách
/// - range: hai ô nhập khoảng số (Năm sản xuất, Số km)
class ListingFilterAttributeSection extends StatelessWidget {
  final CategoryAttributeModel attribute;
  final AttributeFilterValue? value;
  final void Function(String key, String value) onToggle;
  final void Function(String key, String? value) onSelect;
  final void Function(String key, {num? min, num? max}) onRange;

  const ListingFilterAttributeSection({
    super.key,
    required this.attribute,
    required this.value,
    required this.onToggle,
    required this.onSelect,
    required this.onRange,
  });

  @override
  Widget build(BuildContext context) {
    final key = attribute.key;
    final selected = value?.values ?? const <String>{};
    // Có / không ("Đã tiêm phòng"): một chip "Có", chọn lại là bỏ
    if (attribute.type == AttributeType.boolean) {
      return ListingFilterSection(
        title: attribute.label.of(context),
        child: ListingFilterChipWrap(
          children: [
            AppFilterChip(
              label: AppLocalizations.of(context)!.yes,
              selected: selected.contains('true'),
              onTap: () => onSelect(key, 'true'),
            ),
          ],
        ),
      );
    }
    final child = switch (attribute.filter!) {
      AttributeFilterKind.single ||
      AttributeFilterKind.multi => ListingFilterChipWrap(
        children: [
          for (final option in attribute.options)
            AppFilterChip(
              label: option.label.of(context),
              selected: selected.contains(option.value),
              onTap: () => attribute.filter == AttributeFilterKind.multi
                  ? onToggle(key, option.value)
                  : onSelect(key, option.value),
            ),
        ],
      ),
      AttributeFilterKind.list => _OptionField(
        attribute: attribute,
        selected: selected.firstOrNull,
        onSelect: (picked) => onSelect(key, picked),
      ),
      AttributeFilterKind.range => _RangeFields(
        attribute: attribute,
        value: value,
        onChanged: ({min, max}) => onRange(key, min: min, max: max),
      ),
    };
    return ListingFilterSection(
      title: attribute.label.of(context),
      child: child,
    );
  }
}

/// Mọi bộ lọc thuộc tính của danh mục (đã gộp danh mục con)
class ListingFilterAttributeSections extends StatelessWidget {
  final CategoryModel category;
  final Map<String, AttributeFilterValue> values;
  final void Function(String key, String value) onToggle;
  final void Function(String key, String? value) onSelect;
  final void Function(String key, {num? min, num? max}) onRange;

  const ListingFilterAttributeSections({
    super.key,
    required this.category,
    required this.values,
    required this.onToggle,
    required this.onSelect,
    required this.onRange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final attribute in category.filterAttributes)
          ListingFilterAttributeSection(
            key: ValueKey('attr-${category.subcategory?.id}-${attribute.key}'),
            attribute: attribute,
            value: values[attribute.key],
            onToggle: onToggle,
            onSelect: onSelect,
            onRange: onRange,
          ),
      ],
    );
  }
}

/// Dòng "Hãng: Tất cả ›" trong sheet đầy đủ, bấm để mở danh sách có ô tìm
class _OptionField extends StatelessWidget {
  final CategoryAttributeModel attribute;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _OptionField({
    required this.attribute,
    required this.selected,
    required this.onSelect,
  });

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    const all = '';
    final picked = await showAppOptionSheet<String>(
      context,
      title: attribute.label.of(context),
      selected: selected ?? all,
      options: [
        AppSheetOption(all, l10n.listingFilterAny),
        for (final option in attribute.options)
          AppSheetOption(option.value, option.label.of(context)),
      ],
    );
    if (picked == null) return;
    onSelect(picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label =
        attribute.optionOf(selected)?.label.of(context) ??
        l10n.listingFilterAny;
    final active = selected != null;
    return Material(
      color: active
          ? AppColors.primarySoft
          : Colors.white.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: active ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                AppIcons.chevronRight,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khoảng số (VD Năm sản xuất từ 2018 đến 2022). Ô nhập tự cập nhật khi giá
/// trị đổi từ bên ngoài (Xoá bộ lọc).
class _RangeFields extends StatefulWidget {
  final CategoryAttributeModel attribute;
  final AttributeFilterValue? value;
  final void Function({num? min, num? max}) onChanged;

  const _RangeFields({
    required this.attribute,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RangeFields> createState() => _RangeFieldsState();
}

class _RangeFieldsState extends State<_RangeFields> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_RangeFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  /// Chỉ ghi đè ô nhập khi giá trị thật sự khác, để không nhảy con trỏ
  void _sync() {
    void apply(TextEditingController controller, num? value) {
      if (num.tryParse(controller.text) == value) return;
      controller.text = value == null ? '' : '$value';
    }

    apply(_minController, widget.value?.min);
    apply(_maxController, widget.value?.max);
  }

  void _onTyped(String _) => widget.onChanged(
    min: num.tryParse(_minController.text),
    max: num.tryParse(_maxController.text),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = widget.attribute.unit?.of(context) ?? '';
    final min = widget.value?.min;
    final max = widget.value?.max;
    final invalid = min != null && max != null && min > max;

    Widget field(String label, TextEditingController controller) =>
        AppLabeledTextField(
          label: label,
          controller: controller,
          hintText: l10n.listingFilterPriceAny,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onTyped,
          suffix: unit.isEmpty
              ? null
              : Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: field(l10n.listingFilterRangeFrom, _minController)),
            const SizedBox(width: 10),
            Expanded(child: field(l10n.listingFilterRangeTo, _maxController)),
          ],
        ),
        if (invalid) ...[
          const SizedBox(height: 6),
          Text(
            l10n.listingFilterRangeInvalid,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
