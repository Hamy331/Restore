import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/shop_posters_cubit.dart';
import '../../repositories/shop_poster_repository.dart';
import 'shop_posters_mobile_view.dart';

/// Route `/shop-posters`: quản lý poster của shop (nút Shop poster ở menu xoè,
/// gói Cửa hàng). Poster đã duyệt hiện ở trang shop và trang Shop uy tín.
class ShopPostersView extends StatelessWidget {
  const ShopPostersView({super.key, this.repository});

  /// Thay nguồn dữ liệu khi test
  final ShopPosterRepository? repository;

  static const String path = '/shop-posters';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ShopPostersCubit(repository: repository ?? ShopPosterRepository())
          ..load(),
    child: const TResponsiveLayout(mobile: ShopPostersMobileView()),
  );
}
