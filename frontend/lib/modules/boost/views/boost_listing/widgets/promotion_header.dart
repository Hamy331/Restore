import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../../credits/utils/credit_format.dart';
import '../../../models/listing_promotion.dart';
import 'promotion_section.dart';
import 'promotion_thumb.dart';

/// Tin đang quảng bá (ảnh, tên, giá, nhãn đang chạy) và số xu trong ví
class PromotionHeader extends StatelessWidget {
  const PromotionHeader({
    super.key,
    required this.promotion,
    required this.now,
    required this.onTopUp,
  });

  final ListingPromotion promotion;
  final DateTime now;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final price = promotion.price;
    final boosted = promotion.boostRunningUntil?.isAfter(now) ?? false;
    final featured = promotion.featureRunningUntil?.isAfter(now) ?? false;
    return AppGlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PromotionThumb(image: promotion.image, size: 64, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (price != null && price > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        CreditFormat.vnd(context, price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                    if (boosted || featured) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (boosted)
                            PromotionChip(
                              key: const ValueKey('promo-chip-boost'),
                              label: l.accBoost,
                            ),
                          if (featured)
                            const PromotionChip(
                              key: ValueKey('promo-chip-hot'),
                              label: 'Hot sale',
                              color: AppColors.error,
                              background: AppColors.errorBg,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(AppIcons.wallet, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.postingPayBalance(promotion.available),
                  key: const ValueKey('promo-balance'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(onPressed: onTopUp, child: Text(l.postingTopUp)),
            ],
          ),
        ],
      ),
    );
  }
}
