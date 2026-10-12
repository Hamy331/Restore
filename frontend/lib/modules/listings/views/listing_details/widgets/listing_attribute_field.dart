import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_field_message.dart';
import 'package:restore/shared/widgets/app_labeled_text_field.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/app_required_label.dart';
import 'package:restore/shared/widgets/app_select_field.dart';
import 'package:restore/shared/widgets/app_switch_tile.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import '../../../utils/listing_validator.dart';

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

  CategoryAttributeModel get _attribute => widget.attribute;

  bool get _isTextInput =>
      _attribute.type == AttributeType.text ||
      _attribute.type == AttributeType.number;

  @override
  void initState() {
    super.initState();
    if (_isTextInput) {
      _controller = TextEditingController(text: widget.value ?? '');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String? _errorText(AppLocalizations l10n) => switch (widget.error) {
    null => null,
    AttributeError.outOfRange => l10n.numberRangeError(
      '${_attribute.min ?? 0}',
      '${_attribute.max ?? '∞'}',
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
    final label = _attribute.label.of(context);
    final errorText = _errorText(l10n);

    return switch (_attribute.type) {
      AttributeType.select
          when _attribute.options.length <=
              ListingAttributeField.maxInlineOptions =>
        _buildInlineChoices(label, errorText),
      AttributeType.select => AppSelectField(
        label: label,
        isRequired: _attribute.isRequired,
        value: _attribute.optionOf(widget.value)?.label.of(context),
        placeholder: l10n.selectOptionHint,
        errorText: errorText,
        onTap: () => _openOptions(label),
      ),
      AttributeType.boolean => AppSwitchTile(
        label: label,
        value: widget.value == 'true',
        onChanged: (value) => widget.onChanged('$value'),
      ),
      AttributeType.text ||
      AttributeType.number => _buildTextInput(label, errorText),
    };
  }

  Widget _buildInlineChoices(String label, String? errorText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppRequiredLabel(
          text: label,
          isRequired: _attribute.isRequired,
          style: AppRequiredLabel.defaultStyle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 10),
        AppChoiceChips<String>(
          alignment: WrapAlignment.start,
          items: [
            for (final option in _attribute.options)
              AppChoiceItem(option.value, option.label.of(context)),
          ],
          selected: widget.value,
          onSelected: widget.onChanged,
        ),
        AppFieldMessage(errorText: errorText),
      ],
    );
  }

  Widget _buildTextInput(String label, String? errorText) {
    final isNumber = _attribute.type == AttributeType.number;
    final unit = _attribute.unit?.of(context);
    return AppLabeledTextField(
      label: label,
      isRequired: _attribute.isRequired,
      controller: _controller!,
      hintText: _attribute.hint?.of(context),
      maxLength: _attribute.maxLength,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textInputAction: TextInputAction.next,
      inputFormatters: [if (isNumber) FilteringTextInputFormatter.digitsOnly],
      errorText: errorText,
      suffix: unit == null
          ? null
          : Text(
              unit,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
      onChanged: widget.onChanged,
    );
  }
}
