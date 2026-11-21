import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Một gói trong trang Gói tài khoản: tên + mô tả ngắn, giá lớn, quyền lợi và
/// nút hành động. Dùng chung cho mobile (xếp dọc) và desktop (3 cột ngang).
///
/// [actionLabel] null thì không có nút (gói Cá nhân); [onAction] null thì nút
/// bị khoá (hạ gói lúc gói cao hơn còn hạn). [fillHeight] đẩy nút xuống đáy
/// thẻ để các thẻ đặt cạnh nhau có nút thẳng hàng (desktop).
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.priceAmount,
    required this.priceUnit,
    required this.benefits,
    this.isCurrent = false,
    this.actionLabel,
    this.onAction,
    this.lockedHint,
    this.fillHeight = false,
  });

  final SubscriptionPlan plan;

  /// Số xu mỗi kỳ, VD "99" (gói Cá nhân là "0")
  final String priceAmount;

  /// Dòng nhỏ dưới giá, VD "xu / 30 ngày"
  final String priceUnit;
  final List<String> benefits;
  final bool isCurrent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? lockedHint;
  final bool fillHeight;

  IconData get _icon => switch (plan) {
    SubscriptionPlan.personal => AppIcons.user,
    SubscriptionPlan.basic => AppIcons.pro,
    SubscriptionPlan.shop => AppIcons.store,
  };

  String _tagline(AppLocalizations l10n) => switch (plan) {
    SubscriptionPlan.personal => l10n.plansTaglinePersonal,
    SubscriptionPlan.basic => l10n.plansTaglineBasic,
    SubscriptionPlan.shop => l10n.plansTaglineShop,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppGlassContainer(
      padding: const EdgeInsets.all(20),
      borderColor: isCurrent ? AppColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppGlassIconBadge(icon: _icon, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.label(l10n),
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _tagline(l10n),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                _CurrentChip(label: l10n.plansInUse),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            priceAmount,
            style: const TextStyle(
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            priceUnit,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      AppIcons.check,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (fillHeight) const Spacer(),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            AppPrimaryActionButton(
              label: actionLabel!,
              icon: AppIcons.wallet,
              onPressed: onAction,
            ),
            if (onAction == null && lockedHint != null) ...[
              const SizedBox(height: 6),
              Text(
                lockedHint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CurrentChip extends StatelessWidget {
  const _CurrentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
    ),
  );
}
