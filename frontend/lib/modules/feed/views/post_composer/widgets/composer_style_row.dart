import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/post_background.dart';

/// Nút tròn "Aa" nhiều màu; bấm vào thì mở hàng nền màu cho bài chỉ có
/// chữ. Có ảnh hoặc bài quá dài thì nút mờ đi.
class ComposerStyleRow extends StatelessWidget {
  final List<PostBackground> backgrounds;
  final PostBackground? selected;
  final bool expanded;
  final bool enabled;
  final VoidCallback onToggle;
  final ValueChanged<PostBackground?> onSelect;

  const ComposerStyleRow({
    super.key,
    required this.backgrounds,
    required this.selected,
    required this.expanded,
    required this.enabled,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: _StyleButton(
              tooltip: enabled
                  ? l10n.postComposerBackground
                  : l10n.postComposerBackgroundDisabled,
              active: expanded,
              onTap: enabled ? onToggle : null,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppAnimationDurations.normal,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: expanded && enabled
                  ? ListView(
                      key: const ValueKey('backgrounds'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        _Swatch(
                          tooltip: l10n.postComposerNoBackground,
                          selected: selected == null,
                          onTap: () => onSelect(null),
                        ),
                        for (final background in backgrounds)
                          _Swatch(
                            background: background,
                            tooltip: l10n.postComposerBackground,
                            selected: background == selected,
                            onTap: () => onSelect(background),
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleButton extends StatelessWidget {
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  const _StyleButton({
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Color(0xFFF7B733),
                Color(0xFFFC4A1A),
                Color(0xFFA18CD1),
                Color(0xFF4FACFE),
                Color(0xFF43E97B),
                Color(0xFFF7B733),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.textPrimary : Colors.white,
            ),
            alignment: Alignment.center,
            child: Icon(
              AppIcons.textStyle,
              size: 20,
              color: active ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final PostBackground? background;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    this.background,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppAnimationDurations.normal,
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: background == null ? Colors.white : null,
              gradient: background?.gradient,
              border: Border.all(
                color: selected ? AppColors.textPrimary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: background == null
                ? const Icon(
                    AppIcons.block,
                    size: 18,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
