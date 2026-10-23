import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import '../models/posting_quota.dart';

/// Quy định đăng tin cho người bán cá nhân (giới hạn số tin, cách tính,
/// thời gian hiển thị). Số liệu lấy từ [quota] do backend trả về.
Future<void> showPostingRulesSheet(
  BuildContext context, {
  required PostingQuota quota,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<void>(
    context,
    title: l10n.postingRulesTitle,
    subtitle: l10n.postingRulesSubtitle,
    icon: AppIcons.shield,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostingRuleTile(
            icon: AppIcons.listings,
            text: l10n.postingRuleLimit(quota.minLimit, quota.maxLimit),
          ),
          PostingRuleTile(
            icon: AppIcons.checkCircle,
            text: l10n.postingRuleCounted,
          ),
          PostingRuleTile(
            icon: AppIcons.clock,
            text: l10n.postingRuleDuration(quota.displayDays),
          ),
          PostingRuleTile(icon: AppIcons.verified, text: l10n.postingRuleFree),
          PostingRuleTile(
            icon: AppIcons.user,
            text: l10n.postingRulePersonalUse,
          ),
          PostingRuleTile(
            icon: AppIcons.shop,
            text: l10n.postingRuleBusiness(quota.businessLimit),
            muted: true,
          ),
          const SizedBox(height: 12),
          AppSecondaryActionButton(
            label: l10n.close,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Một dòng quy định: icon tròn nhỏ + nội dung
class PostingRuleTile extends StatelessWidget {
  final IconData icon;
  final String text;

  /// Làm nhạt dòng nói về tính năng chưa mở
  final bool muted;

  const PostingRuleTile({
    super.key,
    required this.icon,
    required this.text,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Opacity(
        opacity: muted ? 0.6 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
