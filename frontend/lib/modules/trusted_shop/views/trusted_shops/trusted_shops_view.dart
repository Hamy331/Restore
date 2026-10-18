import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/trusted_shops/trusted_shops_cubit.dart';
import '../../repositories/trusted_shop_repository.dart';
import 'trusted_shops_mobile_view.dart';

/// Route `/trusted-shops`: shop đã xác minh (chính hãng hoặc được ReStore
/// chứng nhận) và sản phẩm của các shop đó, chia thành các khu.
/// `/trusted-shops?shop=<id>` mở trang rồi vào thẳng shop đó, để quay lại
/// vẫn ở trang Shop uy tín (VD bấm banner shop ở trang chủ).
class TrustedShopsView extends StatelessWidget {
  final String? openShopId;

  const TrustedShopsView({super.key, this.openShopId});

  static const String path = '/trusted-shops';

  /// Đường dẫn mở trang rồi vào thẳng shop [shopId]
  static String locationForShop(String shopId) =>
      Uri(path: path, queryParameters: {'shop': shopId}).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrustedShopsCubit(
        repository: AppEnvironment.useMockData
            ? MockTrustedShopRepository()
            : ApiTrustedShopRepository(),
      )..start(),
      child: TResponsiveLayout(
        mobile: TrustedShopsMobileView(openShopId: openShopId),
      ),
    );
  }
}
