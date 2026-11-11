import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../models/promotion_hub.dart';

/// Ví xu, lượt đẩy tặng còn lại và số lượt đã dùng tháng này
class HubSummary extends StatelessWidget {
  const HubSummary({super.key, required this.hub, required this.onTopUp});

  final PromotionHub hub;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppGlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(AppIcons.wallet, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.postingPayBalance(hub.available),
                  key: const ValueKey('hub-balance'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(onPressed: onTopUp, child: Text(l.postingTopUp)),
            ],
          ),
          const SizedBox(height: 4),
          if (hub.freePerMonth > 0)
            _Line(
              icon: AppIcons.boost,
              text: l.hubFreeBoosts(hub.freeLeft, hub.freePerMonth),
            ),
          _Line(
            icon: AppIcons.history,
            text: l.hubThisMonth(hub.boostsThisMonth, hub.featuresThisMonth),
          ),
          if (hub.discountPercent > 0)
            _Line(
              icon: AppIcons.verified,
              text: l.boostDiscountNote(hub.discountPercent),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, right: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
