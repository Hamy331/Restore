import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/modules/account/repositories/profile_repository.dart';
import 'package:restore/modules/feeds/repositories/feeds_repository.dart';
import 'package:restore/modules/trusted_shop/repositories/shop_following_repository.dart';

import '../../bloc/following_hub_cubit.dart';
import 'following_hub_mobile_view.dart';

/// Route `/following` (lối tắt "Đang theo dõi" ở trang chủ): tin mới của
/// các shop đang theo dõi, lọc theo từng shop, người đang theo dõi và gợi ý
/// shop. Chưa theo dõi shop nào thì là màn chọn shop để theo dõi.
class FollowingHubView extends StatelessWidget {
  const FollowingHubView({
    super.key,
    this.shopRepository,
    this.profileRepository,
    this.feedsRepository,
  });

  final ShopFollowingRepository? shopRepository;

  /// Khu "Người bạn theo dõi"; dữ liệu mẫu thì bỏ qua khu này
  final ProfileRepository? profileRepository;

  /// Bài đăng của người mình theo dõi; dữ liệu mẫu thì bỏ qua khu này
  final FeedsRepository? feedsRepository;

  static const String path = '/following';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => FollowingHubCubit(
      shopRepository ?? ShopFollowingRepository(),
      profiles:
          profileRepository ??
          (AppEnvironment.useMockData ? null : ApiProfileRepository()),
      feeds:
          feedsRepository ??
          (AppEnvironment.useMockData ? null : ApiFeedsRepository()),
    )..load(),
    child: const TResponsiveLayout(mobile: FollowingHubMobileView()),
  );
}
