import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/ui/responsive/responsive_content.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Chỉnh một trường và trả bản nháp về màn hình hồ sơ.
class EditProfileFieldPage extends StatefulWidget {
  const EditProfileFieldPage({
    super.key,
    required this.title,
    required this.value,
    required this.fieldKey,
    required this.maxLength,
    this.hint,
    this.helper,
    this.validator,
    this.multiline = false,
  });

  final String title;
  final String value;
  final String fieldKey;
  final int maxLength;
  final String? hint;
  final String? helper;
  final String? Function(String)? validator;
  final bool multiline;

  @override
  State<EditProfileFieldPage> createState() => _EditProfileFieldPageState();
}

class _EditProfileFieldPageState extends State<EditProfileFieldPage> {
  late final _controller = TextEditingController(text: widget.value);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ResponsiveContent(
        maxWidth: 600,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => TextField(
                key: ValueKey(widget.fieldKey),
                controller: _controller,
                maxLength: widget.maxLength,
                minLines: widget.multiline ? 4 : 1,
                maxLines: widget.multiline ? 6 : 1,
                textCapitalization: widget.multiline
                    ? TextCapitalization.sentences
                    : TextCapitalization.none,
                textInputAction: widget.multiline
                    ? TextInputAction.newline
                    : TextInputAction.done,
                onSubmitted: widget.multiline ? null : (_) => _save(),
                onChanged: (_) => setState(() => _error = null),
                style: const TextStyle(fontSize: 15, height: 1.5),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  errorText: _error,
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                          icon: const Icon(AppIcons.close, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _error = null);
                          },
                        ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: Color(0xFFDDE1E6)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: Color(0xFFDDE1E6)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: AppColors.actionPrimary),
                  ),
                ),
              ),
            ),
            if (widget.helper != null && _error == null) ...[
              const SizedBox(height: 12),
              Text(
                widget.helper!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: value.text.trim() == widget.value.trim()
                      ? null
                      : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionPrimary,
                    foregroundColor: AppColors.onAction,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(l.accApplyField),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
