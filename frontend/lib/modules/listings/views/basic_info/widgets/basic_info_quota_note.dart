import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_quota_indicator.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import '../../../models/posting_quota.dart';

/// Số lượt đăng miễn phí còn lại trong chuyên mục đang chọn
class BasicInfoQuotaNote extends StatelessWidget {
  final CategoryPostingQuota quota;

  const BasicInfoQuotaNote({super.key, required this.quota});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final level = AppQuotaLevel.of(quota.used, quota.limit);

    return AppGlassContainer(
      showShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(AppIcons.info, size: 18, color: level.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.postingQuotaRemainingInCategory(
                quota.remaining,
                quota.limit,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 16.0 * quota.limit.clamp(1, 5),
            child: AppQuotaMeter(used: quota.used, limit: quota.limit),
          ),
        ],
      ),
    );
  }
}
