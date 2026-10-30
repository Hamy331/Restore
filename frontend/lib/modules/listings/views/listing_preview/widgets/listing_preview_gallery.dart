import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/gallery/app_image_gallery.dart';

/// Thư viện ảnh vuốt ngang của tin đăng; chạm để xem toàn màn hình
class ListingPreviewGallery extends StatelessWidget {
  final List<String> images;
  const ListingPreviewGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1,
        child: AppImageGallery(images: images, heroTag: 'listing-preview'),
      ),
    );
  }
}
