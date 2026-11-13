import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/app_quota_indicator.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import '../models/listing_enums.dart';
import '../models/posting_quota.dart';
import 'posting_rules_sheet.dart';

/// Lựa chọn của người dùng trên sheet báo hết suất đăng miễn phí
enum PostingLimitAction {
  chooseAnotherCategory,

  /// Đồng ý trả xu cho tin này (ví đủ xu)
  payWithCredits,

  /// Ví không đủ xu: mở trang nạp xu
  topUp,

  /// Mở trang Gói tài khoản để nâng lên Bán chuyên / Cửa hàng
  upgradePlan,
}

/// Báo chuyên mục [category] đã hết suất miễn phí (do chuyên mục, tổng tài
/// khoản hoặc đăng lại nhiều lần), mời đăng bằng xu hoặc nạp thêm, kèm cách
/// giải phóng suất. [atPublish]: đang ở bước bấm Đăng tin, nút chính là
/// "Đăng · X xu" thay vì "Tiếp tục". [reactivate]: đang kích hoạt lại tin
/// hết hạn, nút chính là "Kích hoạt · X xu" và nút phụ là "Để sau" (trả về
/// [PostingLimitAction.chooseAnotherCategory]). Trả về null khi đóng sheet.
Future<PostingLimitAction?> showPostingLimitSheet(
  BuildContext context, {
  required CategoryModel category,
  required PostingQuota quota,
  bool atPublish = false,
  bool reactivate = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  final categoryQuota = quota.forCategory(category.id);
  final block = categoryQuota.blockedBy ?? PostingQuotaBlock.category;
  final price = categoryQuota.extraCredits ?? 0;
  final canPay = categoryQuota.canPayWithCredits;
  final enough = quota.walletAvailable >= price;
  final categoryName = category.name.of(context);

  final message = switch (block) {
    PostingQuotaBlock.category => l10n.postingLimitMessage(
      categoryQuota.limit,
      categoryName,
    ),
    PostingQuotaBlock.total => l10n.postingLimitTotalMessage(
      quota.totalLimit ?? 0,
    ),
    PostingQuotaBlock.recent => l10n.postingLimitRecentMessage(
      categoryName,
      30,
    ),
  };

  return showAppGlassSheet<PostingLimitAction>(
    context,
    title: block == PostingQuotaBlock.total
        ? l10n.postingLimitTotalTitle
        : l10n.postingLimitTitle,
    subtitle: categoryName,
    icon: AppIcons.forCategory(category.iconKey),
    builder: (sheetContext) {
      void pop(PostingLimitAction action) =>
          Navigator.of(sheetContext).pop(action);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UsageRow(quota: quota, categoryQuota: categoryQuota, block: block),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            if (canPay) ...[
              const SizedBox(height: 14),
              _PayCard(
                price: price,
                available: quota.walletAvailable,
                reactivate: reactivate,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryActionButton(
                    label: reactivate
                        ? l10n.postingLater
                        : l10n.chooseAnotherCategory,
                    onPressed: () =>
                        pop(PostingLimitAction.chooseAnotherCategory),
                  ),
                ),
                if (canPay) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: enough
                        ? AppPrimaryActionButton(
                            label: reactivate
                                ? l10n.postingPayReactivate(price)
                                : atPublish
                                ? l10n.postingPayPublish(price)
                                : l10n.postingPayContinue(price),
                            icon: AppIcons.wallet,
                            onPressed: () =>
                                pop(PostingLimitAction.payWithCredits),
                          )
                        : AppPrimaryActionButton(
                            label: l10n.postingTopUp,
                            icon: AppIcons.wallet,
                            onPressed: () => pop(PostingLimitAction.topUp),
                          ),
                  ),
                ],
              ],
            ),
            if (quota.accountType == SellerType.personal)
              Center(
                child: TextButton.icon(
                  onPressed: () => pop(PostingLimitAction.upgradePlan),
                  icon: const Icon(AppIcons.pro, size: 16),
                  label: Text(l10n.postingUpgradeHint),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              canPay ? l10n.postingFreeWaysTitle : l10n.postingLimitWaysTitle,
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
              text: l10n.postingLimitTipExpire(categoryQuota.displayDays),
            ),
          ],
        ),
      );
    },
  );
}

/// Thanh số tin đã dùng: theo chuyên mục, hoặc theo cả tài khoản khi hết tổng
class _UsageRow extends StatelessWidget {
  final PostingQuota quota;
  final CategoryPostingQuota categoryQuota;
  final PostingQuotaBlock block;

  const _UsageRow({
    required this.quota,
    required this.categoryQuota,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = block == PostingQuotaBlock.total && quota.totalLimit != null;
    final used = total ? quota.totalUsed : categoryQuota.used;
    final limit = total ? quota.totalLimit! : categoryQuota.limit;
    return Row(
      children: [
        Expanded(
          child: AppQuotaMeter(used: used, limit: limit, height: 8),
        ),
        const SizedBox(width: 12),
        AppQuotaBadge(
          label: l10n.postingQuotaUsage(used, limit),
          level: AppQuotaLevel.of(used, limit),
        ),
      ],
    );
  }
}

/// Giá xu của tin này và số dư ví
class _PayCard extends StatelessWidget {
  final int price;
  final int available;

  /// Hiện lại tin đã có: xu trừ ngay, không giữ chờ duyệt
  final bool reactivate;

  const _PayCard({
    required this.price,
    required this.available,
    this.reactivate = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final missing = price - available;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.wallet,
                size: 18,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reactivate
                      ? l10n.postingPayReactivateTitle(price)
                      : l10n.postingPayTitle(price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            missing > 0
                ? '${l10n.postingPayBalance(available)} · '
                      '${l10n.postingPayMissing(missing)}'
                : l10n.postingPayBalance(available),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: missing > 0 ? AppColors.error : AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reactivate ? l10n.postingPayNowNote : l10n.postingPayNote,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
