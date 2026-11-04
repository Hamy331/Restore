import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';
import 'package:restore/shared/widgets/app_labeled_choice_row.dart';
import 'package:restore/shared/widgets/app_quota_indicator.dart';
import '../../../models/listing_enums.dart';
import '../../../models/posting_quota.dart';

/// Dòng "Bạn là": loại người bán theo tài khoản (chưa cho tự đổi, bán
/// chuyên sẽ mở sau) kèm số lượt đăng còn lại của chuyên mục đang chọn
class BasicInfoSellerTypeRow extends StatelessWidget {
  final SellerType sellerType;
  final CategoryPostingQuota? categoryQuota;

  const BasicInfoSellerTypeRow({
    super.key,
    required this.sellerType,
    this.categoryQuota,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quota = categoryQuota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabeledChoiceRow<SellerType>(
          label: l10n.youAreLabel,
          selected: sellerType,
          items: [
            sellerType == SellerType.business
                ? AppChoiceItem(SellerType.business, l10n.sellerBusiness)
                : AppChoiceItem(SellerType.personal, l10n.sellerPersonal),
          ],
          onSelected: (_) {},
        ),
        if (quota != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.postingQuotaRemainingInCategory(
                    quota.remaining,
                    quota.limit,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                child: AppQuotaMeter(used: quota.used, limit: quota.limit),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
