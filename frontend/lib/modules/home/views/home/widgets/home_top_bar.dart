import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/shared/widgets/app_image_icon.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Đầu trang chủ trên nền cam: chọn khu vực, bên dưới là lời chào kèm tên
/// người dùng. Nút tin nhắn và thông báo nằm cạnh ô tìm kiếm ghim
/// ([HomeSearchHeaderDelegate]) để luôn bấm được khi cuộn.
/// Lời chào đổi theo gói của tài khoản để nhận ra đang ở gói nào.
class HomeTopBar extends StatelessWidget {
  final String areaName;
  final String greetingName;
  final SubscriptionPlan plan;
  final VoidCallback onAreaTap;

  /// Nút test đổi gói cạnh nút khu vực, null thì ẩn (khi gọi API thật)
  final VoidCallback? onPlanTap;

  const HomeTopBar({
    super.key,
    required this.areaName,
    required this.greetingName,
    this.plan = SubscriptionPlan.personal,
    required this.onAreaTap,
    this.onPlanTap,
  });

  String _greeting(AppLocalizations l10n) {
    if (greetingName.isEmpty) return l10n.homeGreeting;
    return switch (plan) {
      SubscriptionPlan.personal => l10n.homeGreetingName(greetingName),
      SubscriptionPlan.pro => l10n.homeGreetingPro(greetingName),
      SubscriptionPlan.shop => l10n.homeGreetingShop(greetingName),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppHeaderPalette.gradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: _AreaButton(
                    areaName: areaName,
                    tooltip: l10n.homeChangeArea,
                    onTap: onAreaTap,
                  ),
                ),
                if (onPlanTap != null) ...[
                  const SizedBox(width: 8),
                  _DevPlanChip(
                    tag: l10n.devPlanTag,
                    label: plan.label(l10n),
                    tooltip: l10n.devPlanSwitchTooltip,
                    onTap: onPlanTap!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _greeting(l10n),
                key: ValueKey(plan),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.homeHeadline,
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút khu vực: viên thuốc trắng trên nền cam kem
class _AreaButton extends StatelessWidget {
  final String areaName;
  final String tooltip;
  final VoidCallback onTap;

  const _AreaButton({
    required this.areaName,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppImageIcon(
                  AppImages.uiIcons.location,
                  size: 20,
                  fallback: AppIcons.location,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    areaName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  AppIcons.chevronDown,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút test nhỏ: nhãn TEST và tên gói đang giả lập, bấm để sang gói kế tiếp.
/// Nền trong mờ và nhãn tối để không lẫn với nút thật của trang.
class _DevPlanChip extends StatelessWidget {
  final String tag;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _DevPlanChip({
    required this.tag,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.72),
        shape: StadiumBorder(
          side: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.12),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 9, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const ShapeDecoration(
                    color: AppColors.textPrimary,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  AppIcons.swap,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
