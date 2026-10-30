import 'package:flutter/material.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import 'shop_verification_badge.dart';

/// Logo shop bo góc, viền trắng. Chưa có ảnh thì vẽ chữ cái đầu trên nền
/// màu nhận diện của shop.
class ShopLogo extends StatelessWidget {
  final ShopModel shop;
  final double size;

  const ShopLogo({super.key, required this.shop, this.size = 48});

  /// Màu nhận diện của shop (cột accentColor), thiếu thì theo kiểu xác minh
  static Color accentOf(ShopModel shop) {
    final hex = shop.accentColor?.replaceFirst('#', '');
    final value = hex == null || hex.length != 6
        ? null
        : int.tryParse(hex, radix: 16);
    return value == null
        ? ShopVerificationStyle.of(shop.verificationType).accent
        : Color(0xFF000000 | value);
  }

  /// Tối đa 2 chữ cái đầu của tên, VD "Kodo Camera Official" → "KC"
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentOf(shop);
    final radius = BorderRadius.circular(size * 0.3);
    final logoUrl = shop.logoUrl;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size > 44 ? 2.5 : 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: logoUrl != null
            ? AppLocalImage(path: logoUrl, cacheWidth: (size * 3).round())
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(accent, Colors.white, 0.18)!, accent],
                  ),
                ),
                child: Center(
                  child: Text(
                    initialsOf(shop.name),
                    style: TextStyle(
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
