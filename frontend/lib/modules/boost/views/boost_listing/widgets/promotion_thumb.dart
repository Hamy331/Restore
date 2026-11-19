import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Ảnh đại diện của tin (ảnh mạng, asset hoặc file), bo góc. Tin chưa có
/// ảnh thì hiện khung kem với icon ảnh như thẻ tin ở trang chủ.
class PromotionThumb extends StatelessWidget {
  const PromotionThumb({
    super.key,
    required this.image,
    this.size = 56,
    this.radius = 12,
  });

  final String? image;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: AppColors.cream,
        child: SizedBox.square(
          dimension: size,
          child: path == null || path.isEmpty
              ? const Icon(AppIcons.image, color: AppColors.primaryDark)
              : AppLocalImage(
                  path: path,
                  width: size,
                  height: size,
                  cacheWidth: (size * 3).round(),
                ),
        ),
      ),
    );
  }
}
