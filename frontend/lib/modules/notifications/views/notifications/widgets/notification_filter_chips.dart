import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/notification_filter.dart';

/// Hàng chip lọc cuộn ngang: Tất cả / Chưa đọc / Tin đăng / Ví Xu / Hoạt động
class NotificationFilterChips extends StatelessWidget {
  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onChanged;

  const NotificationFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static String label(AppLocalizations l10n, NotificationFilter filter) =>
      switch (filter) {
        NotificationFilter.all => l10n.notificationsFilterAll,
        NotificationFilter.unread => l10n.notificationsFilterUnread,
        NotificationFilter.listing => l10n.notificationsFilterListing,
        NotificationFilter.wallet => l10n.notificationsFilterWallet,
        NotificationFilter.activity => l10n.notificationsFilterActivity,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: NotificationFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = NotificationFilter.values[index];
          final isSelected = filter == selected;
          return Semantics(
            selected: isSelected,
            button: true,
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : AppGlass.fill,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : AppGlass.stroke,
                  ),
                ),
                child: Text(
                  label(l10n, filter),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
