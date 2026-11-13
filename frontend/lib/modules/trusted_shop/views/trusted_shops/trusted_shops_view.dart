import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/followed_shops/followed_shops_cubit.dart';
import '../../bloc/trusted_shops/trusted_shops_cubit.dart';
import '../../repositories/shop_following_repository.dart';
import '../../repositories/trusted_shop_repository.dart';
import 'trusted_shops_mobile_view.dart';

/// Route `/trusted-shops`: shop đã xác minh (chính hãng hoặc được ReStore
/// chứng nhận) và sản phẩm của các shop đó, chia thành các khu.
/// `/trusted-shops?shop=<id>` mở trang rồi vào thẳng shop đó, để quay lại
/// vẫn ở trang Shop uy tín (VD bấm banner shop ở trang chủ).
class TrustedShopsView extends StatelessWidget {
  final String? openShopId;

  const TrustedShopsView({
    super.key,
    this.openShopId,
    this.repository,
    this.followingRepository,
  });
  final TrustedShopRepository? repository;

  /// Dải "Shop bạn theo dõi"; mặc định theo [repository] (mock hay API)
  final ShopFollowingRepository? followingRepository;

  static const String path = '/trusted-shops';

  /// Đường dẫn mở trang rồi vào thẳng shop [shopId]
  static String locationForShop(String shopId) =>
      Uri(path: path, queryParameters: {'shop': shopId}).toString();

  @override
  Widget build(BuildContext context) {
    final repository =
        this.repository ??
        (AppEnvironment.useMockData
            ? MockTrustedShopRepository()
            : ApiTrustedShopRepository());
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TrustedShopsCubit(repository: repository)..start(),
        ),
        BlocProvider(
          create: (_) => FollowedShopsCubit(
            followingRepository ??
                (repository is MockTrustedShopRepository
                    ? MockShopFollowingRepository()
                    : ShopFollowingRepository()),
          )..load(),
        ),
      ],
      child: TResponsiveLayout(
        mobile: TrustedShopsMobileView(openShopId: openShopId),
      ),
    );
  }
}
