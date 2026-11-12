import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/modules/trusted_shop/repositories/shop_following_repository.dart';

import '../../bloc/shop_followers_cubit.dart';
import 'shop_followers_mobile_view.dart';

/// Route `/my-shop/followers`: người đang theo dõi shop của mình (bấm ô
/// "Người theo dõi" ở trang Quản lý shop)
class ShopFollowersView extends StatelessWidget {
  const ShopFollowersView({super.key, this.repository});

  final ShopFollowingRepository? repository;

  static const String path = '/my-shop/followers';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ShopFollowersCubit(repository ?? ShopFollowingRepository())..load(),
    child: const TResponsiveLayout(mobile: ShopFollowersMobileView()),
  );
}
