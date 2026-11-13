import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../../credits/utils/credit_format.dart';
import '../../../models/listing_promotion.dart';
import 'promotion_section.dart';

/// Các lượt đẩy tin / Hot sale gần đây của tin, mới trước
class PromotionHistory extends StatelessWidget {
  const PromotionHistory({super.key, required this.history, required this.now});

  final List<PromotionRecord> history;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PromotionSection(
      key: const ValueKey('promo-history'),
      icon: AppIcons.history,
      title: l.promoHistoryTitle,
      child: history.isEmpty
          ? Text(
              l.promoHistoryEmpty,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (final (index, item) in history.indexed) ...[
                  if (index > 0) const Divider(height: 16),
                  _Row(item: item, now: now),
                ],
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.now});
  final PromotionRecord item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bump = item.kind == PromotionKind.bump;
    final running = item.isRunningAt(now);
    return Row(
      children: [
        Icon(
          bump ? AppIcons.boost : AppIcons.hot,
          size: 18,
          color: bump ? AppColors.primaryDark : AppColors.error,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bump
                    ? l.boost24Hours
                    : l.promoHistoryFeature(item.durationDays),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${CreditFormat.dateTime(context, item.startsAt)} – '
                '${CreditFormat.dateTime(context, item.endsAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (item.free) ...[
          PromotionChip(
            label: l.promoFree,
            color: AppColors.info,
            background: AppColors.infoBg,
          ),
          const SizedBox(width: 6),
        ],
        running
            ? PromotionChip(label: l.promoRunning)
            : PromotionChip(
                label: l.promoEnded,
                color: AppColors.textSecondary,
                background: AppColors.cream,
              ),
      ],
    );
  }
}
