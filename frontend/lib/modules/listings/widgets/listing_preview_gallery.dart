import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Thư viện ảnh vuốt ngang của tin đăng, có bộ đếm "1 / N"
class ListingPreviewGallery extends StatefulWidget {
  final List<String> images;
  const ListingPreviewGallery({super.key, required this.images});

  @override
  State<ListingPreviewGallery> createState() => _ListingPreviewGalleryState();
}

class _ListingPreviewGalleryState extends State<ListingPreviewGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final images = widget.images;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(
          color: AppColors.surface,
          child: images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noPhotosYet,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) =>
                          setState(() => _current = index),
                      itemBuilder: (_, index) =>
                          AppLocalImage(path: images[index]),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.galleryPosition(
                            _current.clamp(0, images.length - 1) + 1,
                            images.length,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
