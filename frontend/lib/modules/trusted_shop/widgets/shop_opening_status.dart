import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/shop_opening_hours.dart';
import 'package:restore/l10n/app_localizations.dart';

/// "Đang mở cửa · Đóng lúc 21:00" / "Đã đóng cửa · Mở lúc 08:00 Thứ Hai";
/// không hiện gì khi shop chưa đặt giờ mở cửa
class ShopOpeningStatus extends StatelessWidget {
  const ShopOpeningStatus({super.key, required this.hours, this.now});

  final List<ShopOpeningDay> hours;

  /// Giờ để tính (test truyền vào), mặc định giờ máy
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final state = shopOpenStateAt(hours, now ?? DateTime.now());
    if (state == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final day = state.opensDay;
    final text = state.open
        ? l10n.shopOpenNow(state.closesAt!)
        : day == null
        ? l10n.shopOpensToday(state.opensAt!)
        : l10n.shopOpensOn(state.opensAt!, l10n.shopWeekday('$day'));
    final color = state.open ? AppColors.success : AppColors.textSecondary;
    return Row(
      key: const ValueKey('shop-opening-status'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.clock, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: state.open ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}
