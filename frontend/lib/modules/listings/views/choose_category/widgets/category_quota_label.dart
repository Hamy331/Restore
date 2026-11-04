import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_quota_indicator.dart';
import '../../../models/posting_quota.dart';

/// Số tin đã đăng trong một chuyên mục, hiện dưới mô tả danh mục.
/// Chưa đăng tin nào thì không hiện cho đỡ rối.
class CategoryQuotaLabel extends StatelessWidget {
  final CategoryPostingQuota quota;

  const CategoryQuotaLabel({super.key, required this.quota});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final level = AppQuotaLevel.of(quota.used, quota.limit);

    return Row(
      children: [
        AppQuotaBadge(
          level: level,
          label: quota.isFull
              ? l10n.postingQuotaFull(quota.limit)
              : l10n.postingQuotaUsage(quota.used, quota.limit),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 12.0 * quota.limit.clamp(1, 6),
          child: AppQuotaMeter(used: quota.used, limit: quota.limit, height: 4),
        ),
      ],
    );
  }
}
