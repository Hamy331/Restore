import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import '../../../models/wanted_alert_item.dart';
import '../../../utils/wanted_alert_criteria.dart';
import '../../../widgets/wanted_alert_criteria_chips.dart';

/// Phần dưới đầu trang chi tiết: đủ mọi tiêu chí của thông báo (cả tiêu
/// chí để trống như "Toàn quốc") và mức độ giống
class WantedAlertDetailSummary extends StatelessWidget {
  final WantedAlertItem item;

  const WantedAlertDetailSummary({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final alert = item.alert;
    final language = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: WantedAlertCriteriaChips(
        color: AppColors.surface,
        criteria: [
          ...WantedAlertCriteria.of(
            context,
            filter: alert.filter,
            categoryName: item.categoryName?.resolve(language),
            areaLabel: alert.areaLabel,
          ),
          WantedAlertCriteria.level(context, alert.matchLevel),
        ],
      ),
    );
  }
}
