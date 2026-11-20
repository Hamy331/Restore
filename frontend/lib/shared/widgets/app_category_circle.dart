import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/category_model.dart';

const _photoDir = 'assets/images/categories/photos';

/// Ảnh thật của ô Hot sale ở hàng danh mục
const hotSaleCategoryPhoto = '$_photoDir/hot-sale.jpg';

/// Ảnh thật tương ứng với icon 3D của danh mục: cùng tên file, nằm trong
/// `assets/images/categories/photos/` (VD `phones.png` → `photos/phones.jpg`).
/// Null nếu danh mục không dùng icon trong assets.
String? categoryPhotoFor(CategoryModel category) {
  final icon = category.imageUrl;
  if (icon == null || !icon.startsWith('assets/')) return null;
  final file = icon.split('/').last;
  final dot = file.lastIndexOf('.');
  final name = dot > 0 ? file.substring(0, dot) : file;
  return '$_photoDir/$name.jpg';
}

/// Vòng tròn của một ô danh mục, dùng chung cho điện thoại và web desktop:
/// có ảnh thật thì ảnh phủ kín vòng tròn, chưa có (hoặc lỗi) thì hiện
/// [fallback] (icon 3D) trên nền kem như cũ.
class AppCategoryCircle extends StatelessWidget {
  const AppCategoryCircle({
    super.key,
    required this.size,
    required this.fallback,
    this.photo,
    this.background = AppColors.cream,
  });

  final double size;
  final String? photo;
  final Widget fallback;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final icon = Center(child: fallback);
    final photo = this.photo;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: photo == null
          ? icon
          : Image.asset(
              photo,
              fit: BoxFit.cover,
              width: size,
              height: size,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (_, _, _) => icon,
            ),
    );
  }
}
