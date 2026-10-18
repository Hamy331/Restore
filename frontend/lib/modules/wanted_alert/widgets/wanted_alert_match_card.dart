import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';

import '../models/wanted_alert_match.dart';

/// Thẻ tin gần giống thông báo: [AppListingCard] kèm nhãn ở mép dưới ảnh,
/// "Mới" với tin khớp chưa xem, còn lại là độ giống (VD "Giống 82%").
/// Dùng ở trang tạo (tin gợi ý) và trang chi tiết (tin đã khớp).
class WantedAlertMatchCard extends StatelessWidget {
  final WantedAlertMatch match;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const WantedAlertMatchCard({
    super.key,
    required this.match,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(
            child: AppListingCard(
              item: match.item,
              onTap: onTap,
              onFavoriteTap: onFavoriteTap,
            ),
          ),
          // Ảnh thẻ vuông theo chiều rộng, nhãn nằm sát mép dưới ảnh
          Positioned(
            left: 8,
            top: constraints.maxWidth - 30,
            child: IgnorePointer(
              child: _Badge(
                label: match.isNew
                    ? l10n.wantedAlertNewTag
                    : l10n.wantedAlertMatchPercent(match.percent),
                highlighted: match.isNew,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _Badge({required this.label, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: highlighted
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.9),
        shape: StadiumBorder(
          side: BorderSide(
            color: highlighted
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: highlighted ? AppColors.textPrimary : AppColors.primaryDark,
        ),
      ),
    );
  }
}
