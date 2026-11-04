import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/app_quota_indicator.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import '../models/posting_quota.dart';
import 'posting_rules_sheet.dart';

/// Lựa chọn của người dùng trên sheet báo đã đủ số tin
enum PostingLimitAction { chooseAnotherCategory, manageListings }

/// Báo chuyên mục [category] đã đủ số tin của tài khoản cá nhân và gợi ý
/// cách giải phóng suất đăng. Trả về null khi người dùng đóng sheet.
Future<PostingLimitAction?> showPostingLimitSheet(
  BuildContext context, {
  required CategoryModel category,
  required PostingQuota quota,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final categoryQuota = quota.forCategory(category.id);
  final action = await showAppGlassSheet<PostingLimitAction>(
    context,
    title: l10n.postingLimitTitle,
    subtitle: category.name.of(context),
    icon: AppIcons.forCategory(category.iconKey),
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppQuotaMeter(
                  used: categoryQuota.used,
                  limit: categoryQuota.limit,
                  height: 8,
                ),
              ),
              const SizedBox(width: 12),
              AppQuotaBadge(
                label: l10n.postingQuotaUsage(
                  categoryQuota.used,
                  categoryQuota.limit,
                ),
                level: AppQuotaLevel.full,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.postingLimitMessage(
              categoryQuota.limit,
              category.name.of(context),
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.postingLimitWaysTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          PostingRuleTile(
            icon: AppIcons.checkCircle,
            text: l10n.postingLimitTipSold,
          ),
          PostingRuleTile(
            icon: AppIcons.hidden,
            text: l10n.postingLimitTipHide,
          ),
          PostingRuleTile(
            icon: AppIcons.clock,
            text: l10n.postingLimitTipExpire(quota.displayDays),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppSecondaryActionButton(
                  label: l10n.chooseAnotherCategory,
                  onPressed: () => Navigator.of(
                    sheetContext,
                  ).pop(PostingLimitAction.chooseAnotherCategory),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryActionButton(
                  label: l10n.manageMyListings,
                  icon: AppIcons.listings,
                  onPressed: () => Navigator.of(
                    sheetContext,
                  ).pop(PostingLimitAction.manageListings),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // Trang "Tin của tôi" chưa có nên tạm báo đang phát triển
  if (action == PostingLimitAction.manageListings && context.mounted) {
    TSnackBarHelper.showInfo(context, message: l10n.featureComingSoon);
  }
  return action;
}
