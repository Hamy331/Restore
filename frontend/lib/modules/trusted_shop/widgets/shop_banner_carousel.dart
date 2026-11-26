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

  /// Số banner thấy cùng lúc. Màn rộng (tablet / desktop) hiện 2 banner
  /// cạnh nhau để mỗi banner vẫn có cỡ như trên điện thoại
  final int columns;

  const ShopBannerCarousel({
    super.key,
    required this.banners,
    required this.onTap,
    this.columns = 1,
  });

  /// Khoảng cách giữa hai banner cạnh nhau
  static const double _gap = 12;

  /// Số banner thấy cùng lúc theo bề ngang [width] của khu
  static int columnsFor(double width) => width >= 600 ? 2 : 1;

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

  late PageController _controller = _newController();
  Timer? _timer;
  int _page = 0;

  PageController _newController() =>
      PageController(viewportFraction: 1 / widget.columns);

  /// Số trang cuộn được: mỗi trang đẩy thêm một banner, trang cuối vẫn đủ
  /// [ShopBannerCarousel.columns] banner trong khung
  int get _pageCount =>
      (widget.banners.length - widget.columns + 1).clamp(1, 1 << 20);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  @override
  void didUpdateWidget(ShopBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns != widget.columns) {
      // Đổi số cột (xoay máy, kéo giãn cửa sổ): dựng lại bộ điều khiển trang
      _controller.dispose();
      _controller = _newController();
      _page = 0;
    }
    if (_page >= _pageCount) _page = 0;
    if (oldWidget.banners.length != widget.banners.length ||
        oldWidget.columns != widget.columns) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_pageCount < 2 || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _pageCount,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    final columns = widget.columns;
    final pages = _pageCount;
    // Mỗi banner chừa nửa khoảng cách mỗi bên; lề ngoài bù lại để mép
    // banner đầu và cuối vẫn thẳng với phần nội dung
    const halfGap = ShopBannerCarousel._gap / 2;
    final outer = ShopBannerCarousel._sidePadding - (columns > 1 ? halfGap : 0);
    final itemPadding = columns > 1
        ? halfGap
        : ShopBannerCarousel._sidePadding;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          SizedBox(
            height:
                ((constraints.maxWidth - (columns > 1 ? outer * 2 : 0)) /
                        columns -
                    itemPadding * 2) /
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: columns > 1 ? outer : 0,
                ),
                child: PageView.builder(
                  controller: _controller,
                  // Nhiều banner trong khung: banner đầu sát lề trái, cuộn
                  // tới cuối thì banner cuối sát lề phải, không chừa ô trống
                  padEnds: columns == 1,
                  clipBehavior: Clip.hardEdge,
                  itemCount: banners.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (_, index) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: itemPadding),
                    child: _BannerImage(
                      item: banners[index],
                      onTap: () => widget.onTap(banners[index]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (pages > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < pages; index++)
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
