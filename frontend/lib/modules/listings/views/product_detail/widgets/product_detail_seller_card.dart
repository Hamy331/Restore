import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/account_status.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import 'product_detail_section.dart';

/// Thông tin người bán: ảnh đại diện, xác minh, đánh giá, ngày tham gia
/// và số tin đang bán. Chạm để mở trang người bán.
class ProductDetailSellerCard extends StatelessWidget {
  final UserModel seller;
  final int activeListings;
  final VoidCallback onTap;

  const ProductDetailSellerCard({
    super.key,
    required this.seller,
    required this.activeListings,
    required this.onTap,
  });

  static const double _avatarSize = 52;

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 12.5,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final joinedAt = seller.createdAt;
    final name = seller.fullName.isEmpty ? seller.username : seller.fullName;

    return ProductDetailSection(
      title: l10n.productSellerTitle,
      trailing: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          l10n.productSellerProfile,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _Avatar(seller: seller, size: _avatarSize),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (seller.status == AccountStatus.active) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: l10n.productSellerVerified,
                              child: const Icon(
                                AppIcons.verified,
                                size: 16,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            AppIcons.star,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              seller.ratingCount == 0
                                  ? l10n.productSellerNoReviews
                                  : '${seller.ratingAverage.toStringAsFixed(1)}'
                                        ' · ${l10n.reviewCount(seller.ratingCount)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _metaStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          l10n.productSellerListings(activeListings),
                          if (joinedAt != null)
                            l10n.productSellerJoined(
                              DateFormat.yM(locale).format(joinedAt.toLocal()),
                            ),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _metaStyle,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel seller;
  final double size;

  const _Avatar({required this.seller, required this.size});

  /// Chữ cái đầu của tên gọi (chữ cuối trong họ tên tiếng Việt)
  String get _initial {
    final parts = seller.fullName.trim().split(RegExp(r'\s+'));
    final word = parts.last.isEmpty ? seller.username : parts.last;
    return word.isEmpty ? '?' : word.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = seller.avatarUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, Color(0xFFFFE0B0)],
        ),
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: avatarUrl != null
          ? AppLocalImage(path: avatarUrl, cacheWidth: 160)
          : Text(
              _initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
    );
  }
}
