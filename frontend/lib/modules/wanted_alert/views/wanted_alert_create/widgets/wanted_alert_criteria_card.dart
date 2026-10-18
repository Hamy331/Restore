import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../utils/wanted_alert_criteria.dart';

/// Khối kính liệt kê các tiêu chí của thông báo, mỗi dòng một tiêu chí.
/// Dòng khu vực mở trang chọn khu vực, các dòng khác mở sheet Bộ lọc.
class WantedAlertCriteriaCard extends StatelessWidget {
  final List<WantedAlertCriterion> criteria;
  final VoidCallback onEditFilters;
  final VoidCallback onPickArea;

  const WantedAlertCriteriaCard({
    super.key,
    required this.criteria,
    required this.onEditFilters,
    required this.onPickArea,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AppGlass.fieldRadius);
    return Material(
      color: AppGlass.fillStrong,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, criterion) in criteria.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 52,
                color: AppColors.border.withValues(alpha: 0.7),
              ),
            _CriterionRow(
              criterion: criterion,
              // Khu vực luôn nằm cuối danh sách tiêu chí
              onTap: index == criteria.length - 1 ? onPickArea : onEditFilters,
            ),
          ],
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
          TextButton.icon(
            onPressed: onEditFilters,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size.fromHeight(44),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(AppIcons.filter, size: 17),
            label: Text(l10n.wantedAlertEditCriteria),
          ),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final WantedAlertCriterion criterion;
  final VoidCallback onTap;

  const _CriterionRow({required this.criterion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        child: Row(
          children: [
            Icon(criterion.icon, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                criterion.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Text(
                criterion.label,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: criterion.isSet
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: criterion.isSet
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
