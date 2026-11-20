import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/credit_bonus_batch.dart';
import '../../../utils/credit_format.dart';

/// Còn từ chừng này ngày trở xuống thì tô màu cảnh báo (khớp lời nhắc 7 ngày)
const _soonDays = 7;

/// Một lần được tặng / hoàn xu còn trong ví: nguồn, ngày nhận, hạn dùng, số xu
class CreditBonusTile extends StatelessWidget {
  final CreditBonusBatch item;

  /// Mốc tính số ngày còn lại (truyền trong test), mặc định là lúc vẽ
  final DateTime? now;

  const CreditBonusTile({super.key, required this.item, this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = item.daysLeft(now ?? DateTime.now());
    final soon = days != null && days <= _soonDays;
    final accent = soon ? AppColors.warning : AppColors.textSecondary;
    final expiresAt = item.expiresAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: soon ? AppColors.warningBg : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type == CreditTxnType.refund
                      ? l10n.creditBonusFromRefund
                      : l10n.creditBonusFromTopup,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.creditBonusReceived(
                    CreditFormat.date(context, item.grantedAt),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expiresAt == null
                      ? l10n.creditBonusNoExpiry
                      : '${l10n.creditBonusExpiresOn(CreditFormat.date(context, expiresAt))}'
                            ' · ${l10n.creditBonusDaysLeft(days!)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: soon ? FontWeight.w600 : FontWeight.w400,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CreditFormat.points(context, item.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
