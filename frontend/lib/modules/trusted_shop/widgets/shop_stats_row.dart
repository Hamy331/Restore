import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Một dòng số liệu của shop: "★ 4,9 · 18,6k theo dõi · 8 sản phẩm".
/// [showFollowers] false để gọn hơn ở khối sản phẩm theo shop.
class ShopStatsRow extends StatelessWidget {
  final ShopModel shop;
  final bool showFollowers;

  const ShopStatsRow({
    super.key,
    required this.shop,
    this.showFollowers = true,
  });

  /// Điểm đánh giá một chữ số thập phân theo ngôn ngữ (VD "4,9")
  static String formatRating(double rating, String locale) =>
      NumberFormat('0.0', locale).format(rating);

  /// Số lớn dạng rút gọn, dấu thập phân theo ngôn ngữ (VD "18,6k", "1,2M")
  static String formatCount(int count, String locale) {
    final format = NumberFormat('#,##0.#', locale);
    if (count >= 1000000) return '${format.format(count / 1e6)}M';
    if (count >= 1000) return '${format.format(count / 1e3)}k';
    return format.format(count);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    const style = TextStyle(fontSize: 11.5, color: AppColors.textSecondary);
    final parts = [
      if (showFollowers)
        l10n.shopFollowerCount(formatCount(shop.followerCount, locale)),
      l10n.shopListingCount(shop.listingCount),
    ];

    return Row(
      children: [
        const Icon(AppIcons.star, size: 13, color: AppColors.primary),
        const SizedBox(width: 3),
        Text(
          formatRating(shop.ratingAverage, locale),
          style: style.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            ' · ${parts.join(' · ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
