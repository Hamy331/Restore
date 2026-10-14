import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_field_message.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/app_required_label.dart';
import '../models/listing_detail_field.dart';
import '../models/listing_option.dart';

/// Một dòng trong phần "Thông tin chi tiết", hiển thị theo loại trường
class ListingDetailFieldRow extends StatefulWidget {
  final ListingDetailField field;
  final String? value;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const ListingDetailFieldRow({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<ListingDetailFieldRow> createState() => _ListingDetailFieldRowState();
}

class _ListingDetailFieldRowState extends State<ListingDetailFieldRow> {
  TextEditingController? _textController;

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle _valueStyle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  @override
  void initState() {
    super.initState();
    if (widget.field.type == ListingDetailFieldType.text) {
      _textController = TextEditingController(text: widget.value ?? '');
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  Future<void> _openPicker(AppLocalizations l10n) async {
    final selected = await showAppOptionSheet<String>(
      context,
      title: widget.field.label(l10n),
      selected: widget.value,
      options: [
        for (final option in widget.field.options)
          AppSheetOption(option.value, option.labelOf(l10n)),
      ],
    );
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final field = widget.field;
    final label = AppRequiredLabel(
      text: field.label(l10n),
      isRequired: field.isRequired,
      style: _labelStyle,
    );

    final Widget row = switch (field.type) {
      ListingDetailFieldType.choice => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            label,
            const SizedBox(width: 12),
            Expanded(
              child: AppChoiceChips<String>(
                items: [
                  for (final option in field.options)
                    AppChoiceItem(option.value, option.labelOf(l10n)),
                ],
                selected: widget.value,
                onSelected: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
      ListingDetailFieldType.picker => InkWell(
        onTap: () => _openPicker(l10n),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              label,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  field.options.byValue(widget.value)?.labelOf(l10n) ?? '',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _valueStyle,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
      ListingDetailFieldType.text => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            label,
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _textController,
                onChanged: widget.onChanged,
                keyboardType: field.keyboardType,
                textAlign: TextAlign.end,
                style: _valueStyle.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: field.hint?.call(l10n),
                  hintStyle: _valueStyle.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        AppFieldMessage(
          errorText: widget.hasError
              ? (field.type == ListingDetailFieldType.text
                    ? l10n.fieldRequiredError
                    : l10n.fieldSelectRequiredError)
              : null,
        ),
        if (widget.hasError) const SizedBox(height: 8),
      ],
    );
  }
}
