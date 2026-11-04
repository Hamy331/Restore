import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Một dòng danh mục: ảnh bo góc, tên, mô tả ngắn và mũi tên.
/// [footer] hiện dưới mô tả (VD số tin đã đăng); [isLocked] làm mờ ảnh và
/// đổi mũi tên thành ổ khoá khi chuyên mục đã đủ số tin.
class CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imagePath;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final bool showBottomBorder;
  final Widget? footer;
  final bool isLocked;

  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.fallbackIcon,
    required this.onTap,
    this.imagePath,
    this.showBottomBorder = true,
    this.footer,
    this.isLocked = false,
  });

  static const double imageSize = 64;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isLocked ? 0.5 : 1,
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.primarySoft.withValues(alpha: 0.8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imagePath == null
                      ? Icon(
                          fallbackIcon,
                          color: AppColors.primaryDark,
                          size: 34,
                        )
                      : AppLocalImage(
                          path: imagePath!,
                          fallbackIcon: fallbackIcon,
                          cacheWidth:
                              (imageSize *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (footer != null) ...[const SizedBox(height: 6), footer!],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLocked ? AppIcons.lock : AppIcons.chevronRight,
              color: isLocked ? AppColors.textSecondary : AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}
