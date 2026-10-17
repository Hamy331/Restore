import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

/// Đầu trang Gần bạn trên nền cam kem như trang chủ: nút quay lại, tiêu đề
/// kèm mô tả ngắn và nút lấy lại vị trí GPS.
class NearbyTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRelocate;

  /// Đang lấy vị trí: nút định vị đổi thành loading
  final bool isLocating;

  const NearbyTopBar({
    super.key,
    required this.onBack,
    required this.onRelocate,
    this.isLocating = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppHeaderPalette.gradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
        child: Row(
          children: [
            _CircleButton(
              tooltip: l10n.back,
              onTap: onBack,
              child: const Icon(
                AppIcons.back,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nearbyTitle,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.nearbySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CircleButton(
              tooltip: l10n.nearbyRelocate,
              onTap: isLocating ? null : onRelocate,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLocating
                    ? const AppLoadingIndicator(
                        key: ValueKey('busy'),
                        dotSize: 4,
                      )
                    : const Icon(
                        AppIcons.myLocation,
                        key: ValueKey('idle'),
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút tròn trắng trên nền cam kem, cùng kiểu nút ở đầu trang chủ
class _CircleButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  const _CircleButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: _size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
