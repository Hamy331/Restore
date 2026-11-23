import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';

import 'home_header_icon_button.dart';
import 'home_notification_button.dart';

/// Hàng đầu trang chủ trên nền trắng: logo bên trái, Tin đã lưu và Thông báo
/// bên phải (Tin nhắn và Tài khoản đã có ở thanh điều hướng dưới đáy). Cuộn
/// đi khi kéo trang; ô tìm kiếm bên dưới thì ghim lại.
class HomeTopBar extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onSavedTap;
  final VoidCallback onNotificationsTap;

  /// Nút test đổi gói cạnh logo, null thì ẩn (khi gọi API thật)
  final VoidCallback? onPlanTap;

  const HomeTopBar({
    super.key,
    this.plan = SubscriptionPlan.personal,
    required this.onSavedTap,
    required this.onNotificationsTap,
    this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    // Nền trắng: icon thanh trạng thái màu tối
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 2),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  AppImages.appLogos.appLogo,
                  width: 30,
                  height: 30,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Restore',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppHeaderPalette.top,
                ),
              ),
              if (onPlanTap != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: _DevPlanChip(
                    tag: l10n.devPlanTag,
                    label: plan.label(l10n),
                    tooltip: l10n.devPlanSwitchTooltip,
                    onTap: onPlanTap!,
                  ),
                ),
              ],
              const Spacer(),
              HomeHeaderIconButton(
                icon: AppIcons.favorite,
                tooltip: vi ? 'Tin đã lưu' : 'Saved',
                onTap: onSavedTap,
              ),
              HomeNotificationButton(
                tooltip: l10n.notifications,
                onTap: onNotificationsTap,
              ),
            ],
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
