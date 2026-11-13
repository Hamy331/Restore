import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/post_audience.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Đầu trang viết bài: nút đóng, chọn ai được xem và nút Đăng.
class ComposerTopBar extends StatelessWidget {
  final PostAudience audience;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback onAudienceTap;
  final VoidCallback onSubmit;

  const ComposerTopBar({
    super.key,
    required this.audience,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onClose,
    required this.onAudienceTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.close,
            onPressed: onClose,
            icon: const Icon(AppIcons.close, size: 26),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: InkWell(
              onTap: onAudienceTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          audience.icon,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            audience.label(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          AppIcons.chevronDown,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                    Text(
                      audience.description(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PostButton(
            label: l10n.postComposerSubmit,
            enabled: canSubmit,
            loading: isSubmitting,
            onTap: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _PostButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFF08A3C)],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 16, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  loading
                      ? const AppLoadingIndicator(
                          dotSize: 5,
                          color: Colors.white,
                        )
                      : const Icon(
                          AppIcons.send,
                          size: 16,
                          color: Colors.white,
                        ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
