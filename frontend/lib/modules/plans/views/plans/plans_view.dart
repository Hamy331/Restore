import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';

import '../../bloc/plans_cubit.dart';
import '../../repositories/plans_repository.dart';
import 'plans_mobile_view.dart';

/// Trang Gói tài khoản: so sánh gói, mua / gia hạn / nâng cấp bằng xu
class PlansView extends StatelessWidget {
  const PlansView({super.key, this.repository, this.categoryRepository});

  static const String path = '/plans';

  final PlansRepository? repository;
  final CategoryRepository? categoryRepository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PlansCubit(
      repository: repository,
      categoryRepository: categoryRepository,
    )..load(),
    child: const PlansMobileView(),
  );
}
