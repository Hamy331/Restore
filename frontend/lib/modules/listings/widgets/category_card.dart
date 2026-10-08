import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imagePath;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final bool showBottomBorder;

  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    this.imagePath,
    required this.fallbackIcon,
    required this.onTap,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        decoration: BoxDecoration(
          // Viền đáy mảnh để phân tách các danh mục[cite: 69]
          border: showBottomBorder
              ? const Border(
                  bottom: BorderSide(color: AppColors.border, width: 1.0),
                )
              : null,
        ),
        child: Row(
          children: [
            // Khung ảnh nền viền mỏng bo tròn[cite: 69]
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: AppColors.cream,
                border: Border.all(color: AppColors.primarySoft, width: 2.0),
              ),
              child: _buildImageOrIcon(),
            ),
            const SizedBox(width: 20.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            const Icon(
              Icons.chevron_right,
              color: AppColors.primaryDark,
            ), // Mũi tên màu nâu cam[cite: 69]
          ],
        ),
      ),
    );
  }

  Widget _buildImageOrIcon() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18.0),
        child: Image.asset(
          imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(fallbackIcon, color: AppColors.primaryDark, size: 36),
        ),
      );
    }
    return Icon(fallbackIcon, color: AppColors.primaryDark, size: 36);
  }
}
