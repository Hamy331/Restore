import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Một gói trong trang Gói tài khoản: tên, giá, quyền lợi và nút hành động.
/// [actionLabel] null thì không có nút (gói Cá nhân); [onAction] null thì nút
/// bị khoá (hạ gói lúc gói cao hơn còn hạn).
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.price,
    required this.benefits,
    this.isCurrent = false,
    this.actionLabel,
    this.onAction,
    this.lockedHint,
  });

  final SubscriptionPlan plan;
  final String price;
  final List<String> benefits;
  final bool isCurrent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? lockedHint;

  IconData get _icon => switch (plan) {
    SubscriptionPlan.personal => AppIcons.user,
    SubscriptionPlan.pro => AppIcons.pro,
    SubscriptionPlan.shop => AppIcons.store,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppGlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: isCurrent ? AppColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppGlassIconBadge(icon: _icon, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.label(l10n),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.plansInUse,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      AppIcons.check,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (actionLabel != null) ...[
            const SizedBox(height: 8),
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
