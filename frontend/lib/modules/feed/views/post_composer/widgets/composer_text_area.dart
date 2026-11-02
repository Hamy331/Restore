import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/post_background.dart';

/// Ô nhập nội dung bài. Có nền màu thì chữ to, đậm, căn giữa trên khung
/// gradient; không có thì là ô chữ trơn chiếm phần trống của trang.
class ComposerTextArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final PostBackground? background;
  final ValueChanged<String> onChanged;

  const ComposerTextArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.background,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final background = this.background;
    final light = background?.lightText ?? false;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: null,
      minLines: background == null ? 4 : 1,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      textAlign: background == null ? TextAlign.start : TextAlign.center,
      cursorColor: light ? Colors.white : AppColors.primaryDark,
      style: background == null
          ? const TextStyle(
              fontSize: 18,
              height: 1.4,
              color: AppColors.textPrimary,
            )
          : TextStyle(
              fontSize: 24,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: light ? Colors.white : AppColors.textPrimary,
            ),
      decoration: InputDecoration(
        hintText: l10n.postComposerHint,
        hintStyle: TextStyle(
          color: light
              ? Colors.white.withValues(alpha: 0.75)
              : AppColors.textSecondary.withValues(alpha: 0.8),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isCollapsed: true,
      ),
    );

    return AnimatedContainer(
      duration: AppAnimationDurations.normal,
      curve: AppAnimationDurations.enterCurve,
      margin: background == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: background == null
          ? const EdgeInsets.fromLTRB(20, 16, 20, 8)
          : const EdgeInsets.all(24),
      constraints: BoxConstraints(minHeight: background == null ? 0 : 260),
      alignment: background == null ? Alignment.topLeft : Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: background?.gradient,
        boxShadow: background == null
            ? null
            : [
                BoxShadow(
                  color: background.colors.last.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: field,
    );
  }
}
