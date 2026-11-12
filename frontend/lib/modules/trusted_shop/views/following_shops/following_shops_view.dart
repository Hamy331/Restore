import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/following_feed/following_feed_cubit.dart';
import '../../repositories/shop_following_repository.dart';
import 'following_shops_mobile_view.dart';

/// Route `/following-shops`: các shop uy tín mình đang theo dõi và tin mới
/// nhất của họ.
class FollowingShopsView extends StatelessWidget {
  const FollowingShopsView({super.key, this.repository});

  final ShopFollowingRepository? repository;

  static const String path = '/following-shops';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        FollowingFeedCubit(repository ?? ShopFollowingRepository())..load(),
    child: const TResponsiveLayout(mobile: FollowingShopsMobileView()),
  );
}
