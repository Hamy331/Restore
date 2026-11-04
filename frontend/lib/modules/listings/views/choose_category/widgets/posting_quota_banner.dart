import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import '../../../models/posting_quota.dart';
import '../../../widgets/posting_rules_sheet.dart';

/// Thẻ đầu trang chọn danh mục: loại tài khoản và giới hạn số tin
class PostingQuotaBanner extends StatelessWidget {
  final PostingQuota quota;

  const PostingQuotaBanner({super.key, required this.quota});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppGlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGlassIconBadge(icon: AppIcons.user, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.postingQuotaPersonalTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.postingQuotaBannerMessage(
                    quota.minLimit,
                    quota.maxLimit,
                    quota.displayDays,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showPostingRulesSheet(context, quota: quota),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(AppIcons.chevronRight, size: 16),
                  label: Text(l10n.postingRulesAction),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
