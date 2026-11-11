import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Đầu trang Quản lý shop, giống đầu trang shop người mua thấy: ảnh bìa 3:1
/// và logo bo góc. Bấm ảnh bìa / logo để đổi. [coverBytes] / [logoBytes] là
/// ảnh vừa cắt chưa lưu, ưu tiên hơn ảnh trên server.
class MyShopHeader extends StatelessWidget {
  const MyShopHeader({
    super.key,
    required this.shop,
    required this.accent,
    required this.onCoverTap,
    required this.onLogoTap,
    this.coverUrl,
    this.logoUrl,
    this.coverBytes,
    this.logoBytes,
  });

  /// Shop với tên / màu đang sửa (để logo chữ đổi theo ngay)
  final ShopModel shop;
  final Color accent;
  final String? coverUrl, logoUrl;
  final Uint8List? coverBytes, logoBytes;
  final VoidCallback onCoverTap, onLogoTap;

  static const double _logoSize = 84;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverHeight = constraints.maxWidth / 3;
        return SizedBox(
          height: coverHeight + _logoSize / 2,
          child: Stack(
            children: [
              GestureDetector(
                key: const ValueKey('my-shop-cover'),
                onTap: onCoverTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: coverHeight,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverBytes != null)
                          Image.memory(coverBytes!, fit: BoxFit.cover)
                        else if (coverUrl != null)
                          AppLocalImage(path: coverUrl!, cacheWidth: 1000)
                        else
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.85),
                                  accent.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: _Pill(
                            icon: AppIcons.camera,
                            label: l.msChangeCover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // tên shop cạnh logo, dưới ảnh bìa
              Positioned(
                left: 14 + _logoSize + 12,
                right: 0,
                bottom: 2,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (shop.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(AppIcons.verified, size: 18, color: accent),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 14,
                bottom: 0,
                child: GestureDetector(
                  key: const ValueKey('my-shop-logo'),
                  onTap: onLogoTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _logo(),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            AppIcons.camera,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _logo() {
    final bytes = logoBytes;
    if (bytes == null) {
      return ShopLogo(
        shop: ShopModel(
          id: shop.id,
          name: shop.name,
          logoUrl: logoUrl,
          accentColor: shop.accentColor,
          verificationType: shop.verificationType,
        ),
        size: _logoSize,
      );
    }
    return Container(
      width: _logoSize,
      height: _logoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_logoSize * 0.3),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_logoSize * 0.26),
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
