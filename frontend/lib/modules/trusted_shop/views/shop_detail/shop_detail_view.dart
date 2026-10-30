import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/shop_detail/shop_detail_cubit.dart';
import '../../models/trusted_shop_item.dart';
import '../../repositories/trusted_shop_repository.dart';
import 'shop_detail_mobile_view.dart';

/// Route `/shops/:id`: hồ sơ, chứng nhận và các tin đang bán của một shop.
/// [shop] là thẻ shop vừa bấm (tuỳ chọn) để hiện ngay; thiếu thì trang tự
/// tải. Đóng trang trả về trạng thái theo dõi mới (bool) nếu đã đổi.
class ShopDetailView extends StatelessWidget {
  final String shopId;
  final TrustedShopItem? shop;

  const ShopDetailView({super.key, required this.shopId, this.shop});

  static const String path = '/shops/:id';

  /// Đường dẫn mở trang của shop [shopId]
  static String location(String shopId) => '/shops/$shopId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShopDetailCubit(
        repository: AppEnvironment.useMockData
            ? MockTrustedShopRepository()
            : ApiTrustedShopRepository(),
        shopId: shopId,
        shop: shop,
      )..start(),
      child: const TResponsiveLayout(mobile: ShopDetailMobileView()),
    );
  }
}
