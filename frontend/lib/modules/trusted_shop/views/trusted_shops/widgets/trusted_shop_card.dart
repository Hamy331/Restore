import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../models/trusted_shop_item.dart';
import '../../../widgets/shop_follow_button.dart';
import '../../../widgets/shop_logo.dart';
import '../../../widgets/shop_stats_row.dart';
import '../../../widgets/shop_verification_badge.dart';

/// Thẻ shop trong hàng cuộn ngang: ảnh bìa của shop, logo nổi lên mép bìa,
/// nút theo dõi, tên kèm dấu xác minh, câu giới thiệu và số liệu
class TrustedShopCard extends StatelessWidget {
  final TrustedShopItem item;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  const TrustedShopCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFollowTap,
  });

  static const double width = 280;
  static const double height = 232;
  static const double _coverHeight = 100;
  static const double _logoSize = 60;
  static const double _padding = 16;

  @override
  Widget build(BuildContext context) {
    final shop = item.shop;
    final accent = ShopLogo.accentOf(shop);
    final type = shop.verificationType;
    final coverUrl = shop.coverUrl;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Bìa: ảnh từ API hoặc dải màu nhận diện có hoạ tiết dấu xác minh
              SizedBox(
                height: _coverHeight,
                width: double.infinity,
                child: coverUrl != null
                    ? AppLocalImage(path: coverUrl, cacheWidth: 700)
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(accent, Colors.white, 0.55)!,
                              Color.lerp(accent, Colors.white, 0.82)!,
                            ],
                          ),
                        ),
                        child: Align(
                          alignment: const Alignment(1.15, -1.6),
                          child: Icon(
                            ShopVerificationStyle.of(type).icon,
                            size: 88,
                            color: accent.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
              ),
              Positioned(
                left: _padding,
                top: _coverHeight - _logoSize / 2,
                child: ShopLogo(shop: shop, size: _logoSize),
              ),
              Positioned(
                right: _padding,
                top: _coverHeight + 12,
                child: ShopFollowButton(
                  following: item.isFollowing,
                  accent: accent,
                  onTap: onFollowTap,
                ),
              ),
              Positioned(
                left: _padding,
                right: _padding,
                bottom: _padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            shop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (type != null) ...[
                          const SizedBox(width: 4),
                          ShopVerificationBadge(type: type, iconOnly: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShopStatsRow(shop: shop),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
