import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Ảnh đã chọn hiện ngay dưới nội dung: 1 ảnh thì to hết chiều ngang,
/// nhiều ảnh thì lưới 3 cột. Ảnh đầu có nhãn "Ảnh bìa".
class ComposerSelectedPhotos extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<String> onRemove;

  const ComposerSelectedPhotos({
    super.key,
    required this.photos,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final single = photos.length == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: photos.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: single ? 1 : 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: single ? 4 / 3 : 1,
        ),
        itemBuilder: (_, index) {
          final path = photos[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppLocalImage(path: path, cacheWidth: single ? 900 : 360),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _RemoveButton(
                    tooltip: l10n.postComposerRemovePhoto,
                    onTap: () => onRemove(path),
                  ),
                ),
                if (index == 0 && !single)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          l10n.postComposerCover,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;

  const _RemoveButton({required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(AppIcons.close, size: 16, color: AppColors.surface),
          ),
        ),
      ),
    );
  }
}
