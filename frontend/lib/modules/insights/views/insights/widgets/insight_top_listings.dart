import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../../boost/views/boost_listing/widgets/promotion_section.dart'
    show PromotionChip;
import '../../../../boost/views/boost_listing/widgets/promotion_thumb.dart';
import '../../../../credits/utils/credit_format.dart';
import '../../../models/seller_insights.dart';

/// Các tin nhiều lượt xem nhất trong kỳ, bấm để mở trang quảng bá của tin
class InsightTopListings extends StatelessWidget {
  const InsightTopListings({
    super.key,
    required this.items,
    required this.now,
    required this.onOpen,
  });

  final List<InsightListing> items;
  final DateTime now;
  final ValueChanged<InsightListing> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Text(
        l.insTopEmpty,
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const Divider(height: 16),
          InkWell(
            key: ValueKey('ins-top-${item.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onOpen(item),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                PromotionThumb(image: item.image, size: 48, radius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if ((item.price ?? 0) > 0)
                            CreditFormat.vnd(context, item.price!),
                          l.insTopStats(item.views, item.saves),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isPromotedAt(now))
                  PromotionChip(label: l.promoRunning)
                else
                  const Icon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
