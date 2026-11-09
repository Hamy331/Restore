import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/credit_transaction_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../widgets/credit_transaction_tile.dart';

/// Vài giao dịch gần nhất và nút "Xem tất cả"
class CreditRecentSection extends StatelessWidget {
  final List<CreditTransactionModel> items;
  final VoidCallback onSeeAll;

  const CreditRecentSection({
    super.key,
    required this.items,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.creditRecentTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (items.isNotEmpty)
              TextButton(onPressed: onSeeAll, child: Text(l10n.creditSeeAll)),
          ],
        ),
        const SizedBox(height: 4),
        AppGlassContainer(
          showShadow: false,
          borderRadius: BorderRadius.circular(20),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.creditEmptyHistory,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      CreditTransactionTile(item: items[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
