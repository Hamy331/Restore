import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/app_environment.dart';

import '../../../trusted_shop/models/shop_banner_item.dart';
import '../../../trusted_shop/repositories/trusted_shop_repository.dart';
import '../../../trusted_shop/widgets/shop_banner_carousel.dart';

/// Poster đang chạy của cửa hàng Đối tác, ngay dưới phần đầu trang shop.
/// Chưa có poster hoặc lỗi mạng thì không hiện gì.
class ShopPosterStrip extends StatefulWidget {
  const ShopPosterStrip({super.key, required this.shopId, this.repository});

  final String shopId;
  final TrustedShopRepository? repository;

  @override
  State<ShopPosterStrip> createState() => _ShopPosterStripState();
}

class _ShopPosterStripState extends State<ShopPosterStrip> {
  late final Future<List<ShopBannerItem>> _banners =
      (widget.repository ??
              (AppEnvironment.useMockData
                  ? MockTrustedShopRepository()
                  : ApiTrustedShopRepository()))
          .getShopBanners(widget.shopId)
          .catchError((Object _) => const <ShopBannerItem>[]);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ShopBannerItem>>(
    future: _banners,
    builder: (context, snapshot) {
      final banners = snapshot.data ?? const <ShopBannerItem>[];
      if (banners.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: ShopBannerCarousel(
          key: const ValueKey('shop-poster-strip'),
          banners: banners,
          // poster gắn tin thì mở tin; không gắn thì đang ở chính trang shop
          onTap: (banner) {
            final listingId = banner.banner.listingId;
            if (listingId != null) context.push('/listings/$listingId');
          },
        ),
      );
    },
  );
}
