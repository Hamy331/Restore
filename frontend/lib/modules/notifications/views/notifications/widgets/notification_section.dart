import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import 'notification_tile.dart';

/// Một nhóm thông báo theo ngày ("Hôm nay", "Trước đó") trong khung kính.
/// Vuốt sang trái để xoá một thông báo.
class NotificationSection extends StatelessWidget {
  final String label;
  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onTap;
  final ValueChanged<NotificationModel> onDelete;

  const NotificationSection({
    super.key,
    required this.label,
    required this.items,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppGlassContainer(
          showShadow: false,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  Dismissible(
                    key: ValueKey(items[i].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => onDelete(items[i]),
                    background: _DeleteBackground(
                      label: l10n.notificationsDelete,
                    ),
                    child: NotificationTile(
                      item: items[i],
                      onTap: () => onTap(items[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  final String label;

  const _DeleteBackground({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
