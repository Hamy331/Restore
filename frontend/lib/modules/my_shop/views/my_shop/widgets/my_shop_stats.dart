import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/my_shop_overview.dart';

/// Bốn ô số liệu: người theo dõi, tin đang bán, poster đang chạy, chờ duyệt
class MyShopStatsRow extends StatelessWidget {
  const MyShopStatsRow({super.key, required this.stats, this.onFollowersTap});

  final MyShopStats stats;

  /// Bấm ô người theo dõi để xem danh sách
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = [
      (stats.followerCount, l.msStatFollowers),
      (stats.listingCount, l.msStatListings),
      (stats.runningPosters, l.msStatPostersRunning),
      (stats.pendingPosters, l.msStatPostersPending),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 30, color: AppColors.border),
            Expanded(
              child: _cell(
                i == 0 ? onFollowersTap : null,
                Column(
                  children: [
                    Text(
                      '${items[i].$1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(VoidCallback? onTap, Widget child) => onTap == null
      ? child
      : InkWell(
          key: const ValueKey('my-shop-followers'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
}
