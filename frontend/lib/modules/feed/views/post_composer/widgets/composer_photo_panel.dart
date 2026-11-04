import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/app_selection_badge.dart';

/// Lưới ảnh thay chỗ bàn phím (giống Zalo): ô Chụp ảnh, ô Thư viện rồi
/// tới ảnh gần đây trong máy. Bấm ảnh để chọn, số trên ảnh là thứ tự.
class ComposerPhotoPanel extends StatelessWidget {
  final List<String> recentPhotos;
  final List<String> selected;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final ValueChanged<String> onPhotoTap;

  const ComposerPhotoPanel({
    super.key,
    required this.recentPhotos,
    required this.selected,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.55),
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: recentPhotos.length + 2,
        itemBuilder: (_, index) {
          if (index == 0) {
            return _ActionTile(
              icon: AppIcons.camera,
              label: l10n.postComposerTakePhoto,
              onTap: onCameraTap,
            );
          }
          if (index == 1) {
            return _ActionTile(
              icon: AppIcons.gallery,
              label: l10n.postComposerOpenGallery,
              onTap: onGalleryTap,
            );
          }
          final path = recentPhotos[index - 2];
          final order = selected.indexOf(path);
          return _PhotoTile(
            path: path,
            order: order < 0 ? null : order + 1,
            onTap: () => onPhotoTap(path),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primaryDark),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final int? order;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.path,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppLocalImage(path: path, cacheWidth: 300),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: order == null ? 0 : 1,
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
          ),
          Positioned(top: 8, right: 8, child: AppSelectionBadge(order: order)),
        ],
      ),
    );
  }
}
