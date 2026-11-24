import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import '../../../utils/listing_validator.dart';
import 'listing_form_widgets.dart';

/// Ô nhập một thuộc tính theo danh mục. Widget được chọn theo kiểu dữ liệu
/// trong schema nên dùng được cho mọi loại hàng (điện thoại, xe, thú cưng...).
class ListingAttributeField extends StatefulWidget {
  final CategoryAttributeModel attribute;
  final String? value;
  final AttributeError? error;
  final ValueChanged<String> onChanged;

  /// Danh sách ít lựa chọn thì hiện chip ngay trên form, nhiều thì mở sheet
  static const int maxInlineOptions = 4;

  const ListingAttributeField({
    super.key,
    required this.attribute,
    required this.value,
    required this.onChanged,
    this.error,
  });

  @override
  State<ListingAttributeField> createState() => _ListingAttributeFieldState();
}

class _ListingAttributeFieldState extends State<ListingAttributeField> {
  TextEditingController? _controller;

  /// Đơn vị đang nhập khi ô số có nhiều đơn vị (tháng / năm). Giá trị gửi
  /// lên luôn quy về đơn vị gốc.
  AttributeUnitOption? _unit;

  CategoryAttributeModel get _attribute => widget.attribute;

  bool get _isTextInput =>
      _attribute.type == AttributeType.text ||
      _attribute.type == AttributeType.number;

  @override
  void initState() {
    super.initState();
    if (!_isTextInput) return;
    final base = num.tryParse(widget.value ?? '');
    _unit = _attribute.bestUnitFor(base);
    final unit = _unit;
    _controller = TextEditingController(
      text: unit != null && base != null
          ? _format(base / unit.factor)
          : widget.value ?? '',
    );
  }

  static String _format(num value) =>
      value == value.truncate() ? '${value.toInt()}' : '$value';

  /// Số đang nhập quy về đơn vị gốc rồi báo lên form
  void _emit(String text) {
    final unit = _unit;
    if (unit == null) return widget.onChanged(text);
    final value = num.tryParse(text.trim());
    widget.onChanged(value == null ? '' : _format(value * unit.factor));
  }

  void _selectUnit(AttributeUnitOption unit) {
    if (unit == _unit) return;
    setState(() => _unit = unit);
    _emit(_controller!.text);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String? _errorText(AppLocalizations l10n) => switch (widget.error) {
    null => null,
    AttributeError.outOfRange => l10n.numberRangeError(
      _format((_attribute.min ?? 0) / (_unit?.factor ?? 1)),
      switch (_attribute.max) {
        final max? => _format(max / (_unit?.factor ?? 1)),
        null => '∞',
      },
    ),
    AttributeError.required =>
      _isTextInput ? l10n.fieldRequiredError : l10n.fieldSelectRequiredError,
  };

  Future<void> _openOptions(String label) async {
    final selected = await showAppOptionSheet<String>(
      context,
      title: label,
      selected: widget.value,
      options: [
        for (final option in _attribute.options)
          AppSheetOption(option.value, option.label.of(context)),
      ],
    );
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Trường bắt buộc có dấu * như các form khác
    final label =
        '${_attribute.label.of(context)}${_attribute.isRequired ? ' *' : ''}';
    final errorText = _errorText(l10n);

    return switch (_attribute.type) {
      AttributeType.select
          when _attribute.options.length <=
              ListingAttributeField.maxInlineOptions =>
        ListingLabeledField(
          label: label,
          errorText: errorText,
          child: AppChoiceChips<String>(
            alignment: WrapAlignment.start,
            items: [
              for (final option in _attribute.options)
                AppChoiceItem(option.value, option.label.of(context)),
            ],
            selected: widget.value,
            onSelected: widget.onChanged,
          ),
        ),
      AttributeType.select => ListingLabeledField(
        label: label,
        errorText: errorText,
        child: ListingSelectBox(
          placeholder: l10n.selectOptionHint,
          value: _attribute.optionOf(widget.value)?.label.of(context),
          hasError: errorText != null,
          onTap: () => _openOptions(_attribute.label.of(context)),
        ),
      ),
      AttributeType.boolean => ListingSwitchRow(
        title: _attribute.label.of(context),
        value: widget.value == 'true',
        onChanged: (value) => widget.onChanged('$value'),
      ),
      AttributeType.text ||
      AttributeType.number => _buildTextInput(label, errorText),
    };
  }

  Widget _buildTextInput(String label, String? errorText) {
    final isNumber = _attribute.type == AttributeType.number;
    return ListingLabeledField(
      label: label,
      errorText: errorText,
      child: ListingFilledTextField(
        controller: _controller!,
        hintText: _attribute.hint?.of(context),
        maxLength: _attribute.maxLength,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textInputAction: TextInputAction.next,
        inputFormatters: [if (isNumber) FilteringTextInputFormatter.digitsOnly],
        hasError: errorText != null,
        // Đơn vị luôn hiện (suffixText chỉ hiện khi đang nhập)
        suffix: switch (_unit) {
          final selected? => _UnitSwitch(
            options: _attribute.unitOptions,
            selected: selected,
            onSelected: _selectUnit,
          ),
          null => switch (_attribute.unit?.of(context)) {
            final unit? => Text(
              unit,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            null => null,
          },
        },
        onChanged: _emit,
      ),
    );
  }
}

/// Nút chọn đơn vị nhỏ gọn đặt cuối ô số (tháng | năm)
class _UnitSwitch extends StatelessWidget {
  final List<AttributeUnitOption> options;
  final AttributeUnitOption selected;
  final ValueChanged<AttributeUnitOption> onSelected;

  const _UnitSwitch({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            Semantics(
              button: true,
              selected: option == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: option == selected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    option.label.of(context),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: option == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: option == selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
