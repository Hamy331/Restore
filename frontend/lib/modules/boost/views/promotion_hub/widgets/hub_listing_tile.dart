import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../../credits/utils/credit_format.dart';
import '../../../models/promotion_hub.dart';
import '../../boost_listing/widgets/promotion_section.dart' show PromotionChip;
import '../../boost_listing/widgets/promotion_thumb.dart';
import 'hub_time.dart';

/// Một tin trên trang Boost: trạng thái quảng bá, hạn hiển thị và thao tác
/// nhanh (đẩy tin, gia hạn khi sắp hết hạn, mở trang chi tiết)
class HubListingTile extends StatelessWidget {
  const HubListingTile({
    super.key,
    required this.item,
    required this.now,
    required this.boostCost,
    required this.busy,
    required this.onOpen,
    required this.onBoost,
    required this.onExtend,
  });

  final PromotionHubItem item;
  final DateTime now;

  /// Giá lượt đẩy tiếp theo (0 = dùng lượt tặng)
  final int boostCost;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onBoost;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bumped = item.isBumpedAt(now);
    final featured = item.isFeaturedAt(now);
    final expiring = item.isExpiringAt(now);
    final price = item.price;
    final expiresAt = item.expiresAt;
    return AppGlassContainer(
      key: ValueKey('hub-item-${item.id}'),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PromotionThumb(image: item.image),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (price != null && price > 0)
                              CreditFormat.vnd(context, price),
                            l.accViews(item.viewCount),
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (bumped)
                    PromotionChip(
                      key: const ValueKey('hub-chip-boost'),
                      label: l.hubBoostedFor(
                        hubRemaining(l, item.bumpUntil!.difference(now)),
                      ),
                    ),
                  if (featured)
                    PromotionChip(
                      key: const ValueKey('hub-chip-hot'),
                      label: l.hubFeaturedFor(
                        hubRemaining(l, item.featuredUntil!.difference(now)),
                      ),
                      color: AppColors.error,
                      background: AppColors.errorBg,
                    ),
                  if (item.autoExtend)
                    PromotionChip(
                      label: l.hubAutoExtend,
                      color: AppColors.info,
                      background: AppColors.infoBg,
                    )
                  else if (expiresAt != null && expiresAt.isAfter(now))
                    PromotionChip(
                      key: expiring
                          ? const ValueKey('hub-chip-expiring')
                          : null,
                      label: l.hubExpiresIn(
                        hubRemaining(l, expiresAt.difference(now)),
                      ),
                      color: expiring
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      background: expiring
                          ? AppColors.warningBg
                          : AppColors.cream,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Action(
                          key: ValueKey('hub-boost-${item.id}'),
                          icon: bumped ? AppIcons.clock : AppIcons.boost,
                          label: bumped
                              ? l.promoRunning
                              : boostCost == 0
                              ? l.boostUseFree
                              : l.boostPay(boostCost),
                          primary: !bumped,
                          onTap: bumped || busy ? null : onBoost,
                        ),
                        if (expiring)
                          _Action(
                            key: ValueKey('hub-extend-${item.id}'),
                            icon: AppIcons.calendar,
                            label: l.accExtend,
                            onTap: busy ? null : onExtend,
                          ),
                      ],
                    ),
                  ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppLoadingIndicator(dotSize: 5),
                    )
                  else
                    IconButton(
                      tooltip: l.hubDetails,
                      onPressed: onOpen,
                      icon: const Icon(
                        AppIcons.chevronRight,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: primary
            ? AppColors.primaryDark
            : AppColors.textPrimary,
        backgroundColor: primary ? AppColors.primarySoft : AppColors.cream,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    ),
  );
}
