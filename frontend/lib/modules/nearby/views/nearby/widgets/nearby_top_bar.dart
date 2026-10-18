import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
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
    return AppPageHeader(
      title: l10n.nearbyTitle,
      subtitle: l10n.nearbySubtitle,
      onBack: onBack,
      trailing: _CircleButton(
        tooltip: l10n.nearbyRelocate,
        onTap: isLocating ? null : onRelocate,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLocating
              ? const AppLoadingIndicator(key: ValueKey('busy'), dotSize: 4)
              : const Icon(
                  AppIcons.myLocation,
                  key: ValueKey('idle'),
                  size: 20,
                  color: AppColors.primaryDark,
                ),
        ),
      ),
    );
  }
}

/// Nút tròn trắng trên nền cam kem, cùng kiểu nút ở đầu trang chủ; nhận
/// widget con để đổi sang loading khi đang định vị
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
