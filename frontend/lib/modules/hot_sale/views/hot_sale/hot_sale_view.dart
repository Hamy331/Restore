import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/hot_sale_cubit.dart';
import '../../repositories/hot_sale_repository.dart';
import 'hot_sale_mobile_view.dart';

/// Route `/hot-sale`: tất cả tin đang ở mục Hot sale (tin ưu tiên)
class HotSaleView extends StatelessWidget {
  const HotSaleView({super.key, this.repository});

  /// Thay nguồn dữ liệu khi test
  final HotSaleRepository? repository;

  static const String path = '/hot-sale';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        HotSaleCubit(repository: repository ?? HotSaleRepository())..start(),
    child: const TResponsiveLayout(mobile: HotSaleMobileView()),
  );
}
