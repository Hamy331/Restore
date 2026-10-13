import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../models/home_banner.dart';

/// Banner ảnh trượt ngang theo tỉ lệ [HomeBanner.aspectRatio].
/// Banner chưa có ảnh hiện khung trống ghi kích thước ảnh cần thiết kế.
class HomeBannerCarousel extends StatefulWidget {
  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onTap;

  const HomeBannerCarousel({
    super.key,
    required this.banners,
    required this.onTap,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  static const _autoPlayInterval = Duration(seconds: 5);
  static const double _sidePadding = 16;

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2 || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _timer = Timer.periodic(_autoPlayInterval, (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % widget.banners.length,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final height =
            (constraints.maxWidth - _sidePadding * 2) / HomeBanner.aspectRatio;
        return Column(
          children: [
            SizedBox(
              height: height,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Người dùng tự kéo thì dừng tự chuyển, thả ra chạy lại
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _timer?.cancel();
                  } else if (notification is ScrollEndNotification) {
                    _restartTimer();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.banners.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _sidePadding,
                    ),
                    child: _BannerFrame(
                      banner: widget.banners[index],
                      onTap: () => widget.onTap(widget.banners[index]),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.banners.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.banners.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == _page
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BannerFrame extends StatelessWidget {
  final HomeBanner banner;
  final VoidCallback onTap;

  const _BannerFrame({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final imageUrl = banner.imageUrl;
    return Semantics(
      button: banner.route != null,
      label: AppLocalizations.of(context)!.homeBannerTooltip,
      child: Material(
        color: AppColors.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          onTap: banner.route == null ? null : onTap,
          child: imageUrl == null
              ? CustomPaint(
                  painter: _DashedBorderPainter(radius: 18),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.image,
                          size: 28,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 6),
                        Text(
                          '1200 × 600',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : AppLocalImage(path: imageUrl),
        ),
      ),
    );
  }
}

/// Viền nét đứt cho khung banner trống
class _DashedBorderPainter extends CustomPainter {
  final double radius;
  const _DashedBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.border;
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
