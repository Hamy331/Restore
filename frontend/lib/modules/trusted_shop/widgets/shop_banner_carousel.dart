import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../models/shop_banner_item.dart';
import 'shop_logo.dart';

/// Băng chuyền banner của shop: mỗi banner chỉ là ảnh shop tự thiết kế (đã
/// được admin duyệt), cùng khung và tỉ lệ với banner trang chủ
/// ([aspectRatio], ảnh 1200 × 600). Tự lướt sau vài giây, có chấm chỉ trang.
class ShopBannerCarousel extends StatefulWidget {
  final List<ShopBannerItem> banners;
  final ValueChanged<ShopBannerItem> onTap;

  const ShopBannerCarousel({
    super.key,
    required this.banners,
    required this.onTap,
  });

  /// Giống HomeBanner.aspectRatio để banner shop đặt được ở trang chủ
  static const double aspectRatio = 2;
  static const double _sidePadding = 16;

  /// Chiều cao cả khối (ảnh + chấm chỉ trang) theo bề ngang [width]
  static double heightFor(double width, int count) =>
      (width - _sidePadding * 2) / aspectRatio + (count > 1 ? 16 : 0);

  @override
  State<ShopBannerCarousel> createState() => _ShopBannerCarouselState();
}

class _ShopBannerCarouselState extends State<ShopBannerCarousel> {
  static const Duration _interval = Duration(seconds: 5);

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  @override
  void didUpdateWidget(ShopBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.banners.length) _page = 0;
    if (oldWidget.banners.length != widget.banners.length) _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2 || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % widget.banners.length,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          SizedBox(
            height:
                (constraints.maxWidth - ShopBannerCarousel._sidePadding * 2) /
                ShopBannerCarousel.aspectRatio,
            child: NotificationListener<ScrollNotification>(
              // Người dùng tự kéo thì dừng tự chuyển, thả ra chạy lại
              onNotification: (notification) {
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
                itemCount: banners.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ShopBannerCarousel._sidePadding,
                  ),
                  child: _BannerImage(
                    item: banners[index],
                    onTap: () => widget.onTap(banners[index]),
                  ),
                ),
              ),
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < banners.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: index == _page
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Một banner: ảnh phủ kín khung bo góc, bấm để mở shop. Ảnh lỗi thì hiện
/// nền màu nhận diện của shop.
class _BannerImage extends StatelessWidget {
  final ShopBannerItem item;
  final VoidCallback onTap;

  const _BannerImage({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final banner = item.banner;
    final accent = ShopLogo.accentOf(item.shop);
    return Semantics(
      button: true,
      label: [
        item.shop.name,
        banner.title,
      ].where((s) => s.isNotEmpty).join(': '),
      child: Material(
        color: Color.lerp(accent, Colors.white, 0.8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: onTap,
          child: banner.imageUrl.isEmpty
              ? Center(child: Icon(AppIcons.image, color: accent, size: 32))
              : AppLocalImage(path: banner.imageUrl, cacheWidth: 1200),
        ),
      ),
    );
  }
}
