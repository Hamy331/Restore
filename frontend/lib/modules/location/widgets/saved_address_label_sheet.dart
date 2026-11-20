import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/saved_address_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Sheet đặt tên địa chỉ đã lưu (VD "Nhà"); trả về tên đã nhập ('' là bỏ
/// tên), null khi đóng sheet.
Future<String?> showSavedAddressLabelSheet(
  BuildContext context, {
  String? initial,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<String>(
    context,
    title: l10n.savedAddressRename,
    subtitle: l10n.savedAddressLabelHint,
    icon: AppIcons.edit,
    builder: (_) => _LabelForm(initial: initial),
  );
}

class _LabelForm extends StatefulWidget {
  final String? initial;

  const _LabelForm({this.initial});

  @override
  State<_LabelForm> createState() => _LabelFormState();
}

class _LabelFormState extends State<_LabelForm> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: SavedAddressModel.maxLabelLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: l10n.savedAddressLabelPlaceholder,
              prefixIcon: const Icon(AppIcons.location, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.7),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryActionButton(
            label: l10n.savedAddressSaveLabel,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
