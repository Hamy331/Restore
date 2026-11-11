import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Một gợi ý hành động; có [onTap] thì bấm được (VD mở trang Quảng bá)
class InsightTip extends StatelessWidget {
  const InsightTip({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
    this.color = AppColors.primaryDark,
    this.background = AppColors.primarySoft,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, height: 1.4, color: color),
              ),
            ),
            if (onTap != null)
              Icon(AppIcons.chevronRight, size: 16, color: color),
          ],
        ),
      ),
    ),
  );
}
