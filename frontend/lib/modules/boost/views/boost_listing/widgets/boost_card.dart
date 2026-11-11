import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';

import '../../../../credits/utils/credit_format.dart';
import '../../../models/listing_promotion.dart';
import 'promotion_section.dart';

/// Đẩy tin lên đầu 24 giờ: lượt tặng còn lại hoặc giá xu, đang chạy thì
/// báo tới khi nào được đẩy lại
class BoostCard extends StatelessWidget {
  const BoostCard({
    super.key,
    required this.promotion,
    required this.now,
    required this.busy,
    required this.onBoost,
  });

  final ListingPromotion promotion;
  final DateTime now;
  final bool busy;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final until = promotion.boostRunningUntil;
    final running = until != null && until.isAfter(now);
    final cost = promotion.boostCost;
    final enough = cost <= promotion.available;
    final discount = promotion.discountPercent;
    final note = promotion.boostFree
        ? l.boostFreeNote(promotion.boostFreeLeft, promotion.boostFreePerMonth)
        : discount > 0
        ? '${l.boostPayNote(cost)} ${l.boostDiscountNote(discount)}'
        : l.boostPayNote(cost);
    return PromotionSection(
      key: const ValueKey('promo-boost-card'),
      icon: AppIcons.boost,
      title: l.boost24Hours,
      trailing: promotion.boostFree
          ? PromotionChip(label: l.promoFree)
          : Text(
              CreditFormat.points(context, cost),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l.boostSheetMessage} $note',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (running) ...[
            const SizedBox(height: 10),
            PromotionRunningLine(
              text: l.promoBoostRunning(CreditFormat.dateTime(context, until)),
            ),
          ],
          const SizedBox(height: 14),
          AppPrimaryActionButton(
            key: const ValueKey('promo-boost-button'),
            label: running
                ? l.promoBoostAgainAt(CreditFormat.dateTime(context, until))
                : promotion.boostFree
                ? l.boostUseFree
                : enough
                ? l.boostPay(cost)
                : l.postingTopUp,
            icon: running
                ? AppIcons.clock
                : enough
                ? AppIcons.boost
                : AppIcons.wallet,
            isLoading: busy,
            onPressed: running || busy ? null : onBoost,
          ),
        ],
      ),
    );
  }
}
