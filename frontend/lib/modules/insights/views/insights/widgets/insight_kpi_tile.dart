import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../../credits/utils/credit_format.dart';
import '../../../models/seller_insights.dart';

/// Ô số liệu chính: con số lớn, tên chỉ số và mức thay đổi so với kỳ trước
/// (mũi tên + chữ, không chỉ dựa vào màu)
class InsightKpiTile extends StatelessWidget {
  const InsightKpiTile({
    super.key,
    required this.icon,
    required this.label,
    required this.metric,
  });

  final IconData icon;
  final String label;
  final InsightMetric metric;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final percent = metric.changePercent;
    final (String change, IconData? arrow, Color color) = percent == null
        ? (
            metric.value == 0 ? l.insSame : l.insNew,
            null,
            AppColors.textSecondary,
          )
        : percent > 0
        ? (l.insUp(percent), AppIcons.trendUp, AppColors.success)
        : percent < 0
        ? (l.insDown(-percent), AppIcons.priceDown, AppColors.error)
        : (l.insSame, null, AppColors.textSecondary);
    return AppGlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CreditFormat.number(context, metric.value),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (arrow != null) ...[
                Icon(arrow, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  change,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
