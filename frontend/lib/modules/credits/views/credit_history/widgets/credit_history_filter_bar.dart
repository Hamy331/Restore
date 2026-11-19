import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/credit_history_filter.dart';

/// Thanh lọc dạng phân đoạn: Tất cả / Nạp / Đã dùng / Hoàn
class CreditHistoryFilterBar extends StatelessWidget {
  final CreditHistoryFilter selected;
  final ValueChanged<CreditHistoryFilter> onChanged;

  const CreditHistoryFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  String _label(AppLocalizations l10n, CreditHistoryFilter filter) =>
      switch (filter) {
        CreditHistoryFilter.all => l10n.creditFilterAll,
        CreditHistoryFilter.topup => l10n.creditFilterTopup,
        CreditHistoryFilter.spend => l10n.creditFilterSpend,
        CreditHistoryFilter.refund => l10n.creditFilterRefund,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppGlass.fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppGlass.stroke),
      ),
      child: Row(
        children: [
          for (final filter in CreditHistoryFilter.values)
            Expanded(
              child: Semantics(
                selected: filter == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: filter == selected ? Colors.white : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: filter == selected ? AppGlass.shadow : null,
                    ),
                    child: Text(
                      _label(l10n, filter),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: filter == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: filter == selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
