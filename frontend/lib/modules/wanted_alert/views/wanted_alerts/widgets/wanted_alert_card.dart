import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../models/wanted_alert_item.dart';
import '../../../utils/wanted_alert_criteria.dart';
import '../../../widgets/wanted_alert_criteria_chips.dart';

/// Thẻ một thông báo ở trang quản lý: món cần tìm, tiêu chí đã đặt, số tin
/// khớp (kèm số tin mới) và ảnh vài tin khớp gần nhất
class WantedAlertCard extends StatelessWidget {
  final WantedAlertItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WantedAlertCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final alert = item.alert;
    final lastMatchedAt = alert.lastMatchedAt;
    final createdAt = alert.createdAt;
    final meta = lastMatchedAt != null
        ? l10n.wantedAlertLastMatched(
            TimeAgoFormatter.format(lastMatchedAt, l10n),
          )
        : createdAt != null
        ? l10n.wantedAlertCreatedAt(TimeAgoFormatter.format(createdAt, l10n))
        : l10n.wantedAlertWatching;
    final criteria = [
      ...WantedAlertCriteria.of(
        context,
        filter: alert.filter,
        categoryName: item.categoryName?.resolve(language),
        areaLabel: alert.areaLabel,
      ).where((criterion) => criterion.isSet),
      WantedAlertCriteria.level(context, alert.matchLevel),
    ];

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(
          color: item.newMatchCount > 0
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.border.withValues(alpha: 0.8),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AlertIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.keywords,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.wantedAlertDelete,
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      AppIcons.delete,
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: WantedAlertCriteriaChips(criteria: criteria),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _MatchSummary(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        AppIcons.wantedAlert,
        size: 21,
        color: AppColors.primaryDark,
      ),
    );
  }
}

/// Dòng cuối thẻ: ảnh vài tin khớp, số tin khớp và nhãn số tin mới
class _MatchSummary extends StatelessWidget {
  final WantedAlertItem item;

  const _MatchSummary({required this.item});

  static const double _thumbSize = 36;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        for (final image in item.previewImages) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(
              dimension: _thumbSize,
              child: ColoredBox(
                color: AppColors.cream,
                child: AppLocalImage(path: image, cacheWidth: 120),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (item.previewImages.isNotEmpty) const SizedBox(width: 4),
        Expanded(
          child: Text(
            item.matchCount == 0
                ? l10n.wantedAlertNoMatchYet
                : l10n.wantedAlertMatchCount(item.matchCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: item.matchCount == 0
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ),
        if (item.newMatchCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const ShapeDecoration(
              color: AppColors.primary,
              shape: StadiumBorder(),
            ),
            child: Text(
              l10n.wantedAlertNewMatches(item.newMatchCount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        const SizedBox(width: 4),
        const Icon(
          AppIcons.chevronRight,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}
