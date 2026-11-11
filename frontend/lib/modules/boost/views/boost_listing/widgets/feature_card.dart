import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';

import '../../../../credits/utils/credit_format.dart';
import '../../../../listings/repositories/listings_repository.dart'
    show FeatureOption;
import '../../../models/listing_promotion.dart';
import 'promotion_section.dart';

/// Hot sale (tin ưu tiên) 1/3/7 ngày: chọn gói, giá xu đã giảm theo gói
/// tài khoản. Đang chạy thì khoá chọn và báo ngày kết thúc.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.promotion,
    required this.now,
    required this.busy,
    required this.selectedPackageId,
    required this.onSelect,
    required this.onBuy,
  });

  final ListingPromotion promotion;
  final DateTime now;
  final bool busy;
  final String? selectedPackageId;
  final ValueChanged<String> onSelect;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final until = promotion.featureRunningUntil;
    final running = until != null && until.isAfter(now);
    final options = promotion.featureOptions;
    FeatureOption? selected;
    for (final option in options) {
      if (option.packageId == selectedPackageId) selected = option;
    }
    selected ??= options.isEmpty ? null : options.first;
    final enough = (selected?.credits ?? 0) <= promotion.available;
    final discount = promotion.discountPercent;
    return PromotionSection(
      key: const ValueKey('promo-feature-card'),
      icon: AppIcons.hot,
      title: l.featureAction,
      leading: Image.asset(
        AppImages.coreImages.hotSale,
        height: 30,
        errorBuilder: (_, _, _) =>
            const Icon(AppIcons.hot, color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            discount > 0
                ? '${l.featureSheetMessage} ${l.boostDiscountNote(discount)}'
                : l.featureSheetMessage,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (running) ...[
            const SizedBox(height: 10),
            PromotionRunningLine(
              text: l.featureRunning(CreditFormat.dateTime(context, until)),
            ),
          ],
          const SizedBox(height: 12),
          if (options.isEmpty)
            Text(
              l.featureNoOptions,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final option in options) ...[
              _OptionTile(
                option: option,
                selected: option.packageId == selected?.packageId,
                onTap: running ? null : () => onSelect(option.packageId),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 6),
          AppPrimaryActionButton(
            key: const ValueKey('promo-feature-button'),
            label: running
                ? l.promoRunning
                : selected == null
                ? l.featureAction
                : enough
                ? l.featurePay(selected.credits)
                : l.postingTopUp,
            icon: running
                ? AppIcons.clock
                : enough
                ? AppIcons.hot
                : AppIcons.wallet,
            isLoading: busy,
            onPressed: running || busy || selected == null ? null : onBuy,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final FeatureOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.10)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: ValueKey('promo-option-${option.packageId}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? AppIcons.checkCircleActive : AppIcons.clock,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.featureDays(option.durationDays),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                CreditFormat.points(context, option.credits),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
