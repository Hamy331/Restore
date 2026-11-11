import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_quota_indicator.dart';

import '../../../models/shop_poster_overview.dart';

/// Hạn mức poster: số poster cùng lúc, lượt gửi trong tháng, luật chạy và
/// các cảnh báo (bị khóa gửi, shop chưa xác minh)
class PosterQuotaCard extends StatelessWidget {
  const PosterQuotaCard({super.key, required this.overview});

  final ShopPosterOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final limits = overview.limits;
    final cooldown = limits.cooldownUntil;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Meter(
                  key: const ValueKey('poster-quota-slots'),
                  label: l.spSlots,
                  used: limits.slotsInUse.clamp(0, limits.activeLimit).toInt(),
                  limit: limits.activeLimit,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Meter(
                  key: const ValueKey('poster-quota-monthly'),
                  label: l.spMonthly,
                  used: limits.usedThisMonth,
                  limit: limits.monthlyLimit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l.spRules(limits.minDays, limits.maxDays),
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (cooldown != null)
            _Notice(
              key: const ValueKey('poster-cooldown'),
              icon: AppIcons.lock,
              text: l.spCooldown(DateFormat('dd/MM HH:mm').format(cooldown)),
              color: AppColors.error,
              background: AppColors.errorBg,
            ),
          if (overview.shop?.verified == false)
            _Notice(
              icon: AppIcons.info,
              text: l.spUnverified,
              color: AppColors.info,
              background: AppColors.infoBg,
            ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    super.key,
    required this.label,
    required this.used,
    required this.limit,
  });

  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '$used/$limit',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      AppQuotaMeter(used: used, limit: limit),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, height: 1.4, color: color),
          ),
        ),
      ],
    ),
  );
}
