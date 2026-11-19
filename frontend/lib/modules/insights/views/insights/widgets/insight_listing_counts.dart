import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/seller_insights.dart';

/// Số tin theo trạng thái: đang bán, chờ duyệt, đã ẩn, đã bán
class InsightListingCounts extends StatelessWidget {
  const InsightListingCounts({super.key, required this.insights});

  final SellerInsights insights;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cells = [
      (l.insActive, insights.active),
      (l.insPending, insights.pending),
      (l.insHidden, insights.hidden),
      (l.insSold, insights.sold),
    ];
    return Row(
      children: [
        for (final (index, (label, value)) in cells.indexed) ...[
          if (index > 0)
            Container(width: 1, height: 32, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
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
        ],
      ],
    );
  }
}
