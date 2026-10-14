import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'app_local_image.dart';

/// Lưới ảnh đã chọn + ô thêm ảnh. Ảnh đầu tiên là ảnh bìa,
/// chạm vào một ảnh để đặt làm bìa, bấm X để xoá.
class AppPhotoPickerGrid extends StatelessWidget {
  final List<String> images;
  final int maxImages;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onSetCover;
  final bool hasError;
  final double tileSize;
  final double spacing;

  const AppPhotoPickerGrid({
    super.key,
    required this.images,
    required this.maxImages,
    required this.onAddTap,
    required this.onRemove,
    required this.onSetCover,
    this.hasError = false,
    this.tileSize = 96,
    this.spacing = 12,
  });

  static final BorderRadius _radius = BorderRadius.circular(16);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final decodeWidth = (tileSize * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (var i = 0; i < images.length; i++)
          _PhotoTile(
            // Key theo đường dẫn để animation không bị nhảy khi đổi thứ tự
            key: ValueKey(images[i]),
            path: images[i],
            size: tileSize,
            decodeWidth: decodeWidth,
            isCover: i == 0,
            coverLabel: l10n.coverPhotoBadge,
            onTap: () => onSetCover(i),
            onRemove: () => onRemove(i),
          ),
        if (images.length < maxImages)
          Material(
            color: AppGlass.fillStrong,
            borderRadius: _radius,
            child: InkWell(
              onTap: onAddTap,
              borderRadius: _radius,
              child: AnimatedContainer(
                duration: AppAnimationDurations.fast,
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  borderRadius: _radius,
                  border: Border.all(
                    color: hasError ? AppColors.error : AppGlass.stroke,
                  ),
                ),
                child: const Icon(
                  AppIcons.addPhoto,
                  color: AppColors.primaryDark,
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final double size;
  final int decodeWidth;
  final bool isCover;
  final String coverLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoTile({
    super.key,
    required this.path,
    required this.size,
    required this.decodeWidth,
    required this.isCover,
    required this.coverLabel,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: AppAnimationDurations.fast,
                decoration: BoxDecoration(
                  borderRadius: AppPhotoPickerGrid._radius,
                  color: AppColors.cream,
                  border: Border.all(
                    color: isCover ? AppColors.primary : AppColors.border,
                    width: isCover ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AppLocalImage(path: path, cacheWidth: decodeWidth),
                ),
              ),
            ),
            if (isCover)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    coverLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
