import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import '../utils/wanted_alert_criteria.dart';

/// Hàng chip nhỏ tóm tắt tiêu chí đã đặt của một thông báo (danh mục,
/// khoảng giá, khu vực...). Dùng ở thẻ trang quản lý và đầu trang chi tiết.
class WantedAlertCriteriaChips extends StatelessWidget {
  final List<WantedAlertCriterion> criteria;

  /// Nền chip, trắng trên nền cam kem của đầu trang
  final Color color;

  const WantedAlertCriteriaChips({
    super.key,
    required this.criteria,
    this.color = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final criterion in criteria)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
            decoration: ShapeDecoration(
              color: color,
              shape: StadiumBorder(
                side: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(criterion.icon, size: 13, color: AppColors.primaryDark),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    criterion.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
