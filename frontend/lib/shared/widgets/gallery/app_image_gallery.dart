import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import 'app_page_dots.dart';
import 'app_photo_viewer.dart';

/// Thư viện ảnh vuốt ngang: chấm chỉ báo trang, nhãn "1 / N" và chạm vào
/// ảnh để mở trình xem toàn màn hình (phóng to được).
///
/// Không tự đặt kích thước, nơi dùng bọc trong AspectRatio/SizedBox.
class AppImageGallery extends StatefulWidget {
  final List<String> images;

  /// Tiền tố Hero, phải khác nhau giữa các thư viện cùng hiện trên màn hình
  final String heroTag;

  /// Khoảng cách từ đáy tới chấm chỉ báo, tăng lên khi có nội dung đè mép dưới
  final double indicatorBottom;
  final ValueChanged<int>? onPageChanged;

  const AppImageGallery({
    super.key,
    required this.images,
    required this.heroTag,
    this.indicatorBottom = 12,
    this.onPageChanged,
  });

  @override
  State<AppImageGallery> createState() => _AppImageGalleryState();
}

class _AppImageGalleryState extends State<AppImageGallery> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openViewer() async {
    final index = await showAppPhotoViewer(
      context,
      images: widget.images,
      initialIndex: _current,
      heroTag: widget.heroTag,
      // Nhảy theo ngay khi vuốt trong trình xem để Hero bay về đúng ảnh
      onPageChanged: _jumpTo,
    );
    if (index != null) _jumpTo(index);
  }

  void _jumpTo(int index) {
    if (!mounted || !_controller.hasClients || index == _current) return;
    _controller.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final images = widget.images;

    if (images.isEmpty) {
      return ColoredBox(
        color: AppColors.cream,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.imageBroken,
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
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.cream,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _current = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (_, index) => GestureDetector(
              onTap: _openViewer,
              child: Hero(
                tag: appGalleryHeroTag(widget.heroTag, index),
                flightShuttleBuilder: (_, animation, _, _, _) =>
                    appGalleryHeroShuttle(images[index], animation),
                child: AppLocalImage(path: images[index]),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.indicatorBottom,
          child: Center(
            child: AppPageDots(count: images.length, current: _current),
          ),
        ),
        Positioned(
          right: 12,
          bottom: widget.indicatorBottom - 4,
          child: Semantics(
            button: true,
            label: l10n.galleryOpenFullscreen,
            child: GestureDetector(
              onTap: _openViewer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.expand, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      l10n.galleryPosition(_current + 1, images.length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
