import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Sheet dán liên kết; trả về chuỗi đã nhập ('' là bỏ liên kết), null khi
/// đóng sheet.
Future<String?> showComposerLinkSheet(BuildContext context, {String? initial}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<String>(
    context,
    title: l10n.postComposerLink,
    subtitle: l10n.postComposerLinkHint,
    icon: AppIcons.link,
    builder: (_) => _LinkForm(initial: initial),
  );
}

class _LinkForm extends StatefulWidget {
  final String? initial;

  const _LinkForm({this.initial});

  @override
  State<_LinkForm> createState() => _LinkFormState();
}

class _LinkFormState extends State<_LinkForm> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    var value = _controller.text.trim();
    if (value.isEmpty) {
      Navigator.of(context).pop('');
      return;
    }
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.host.contains('.')) {
      setState(() => _error = l10n.postComposerLinkInvalid);
      return;
    }
    Navigator.of(context).pop(value);
  }

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
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'https://',
              prefixIcon: const Icon(AppIcons.link, size: 20),
              errorText: _error,
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
            label: l10n.postComposerDone,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
