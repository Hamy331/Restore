import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/credit_transaction_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../utils/credit_format.dart';

/// Một dòng giao dịch xu (trang ví và trang lịch sử)
class CreditTransactionTile extends StatelessWidget {
  final CreditTransactionModel item;

  const CreditTransactionTile({super.key, required this.item});

  IconData get _icon => switch (item.type) {
    CreditTxnType.topup => AppIcons.wallet,
    CreditTxnType.bonus => AppIcons.sparkle,
    CreditTxnType.spend => AppIcons.listings,
    CreditTxnType.refund => AppIcons.refresh,
    CreditTxnType.expire => AppIcons.clock,
    CreditTxnType.adjust => AppIcons.edit,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final positive = item.amount >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 19, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CreditFormat.transactionTitle(l10n, item.type),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CreditFormat.transactionSubtitle(context, item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CreditFormat.signed(context, item.amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: positive ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
