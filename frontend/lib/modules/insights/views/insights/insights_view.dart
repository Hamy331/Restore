import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/insights_cubit.dart';
import '../../repositories/insights_repository.dart';
import 'insights_mobile_view.dart';

/// Route `/insights`: thống kê của người bán (mở từ nút Thống kê ở menu xoè)
class InsightsView extends StatelessWidget {
  const InsightsView({super.key, this.repository});

  /// Thay nguồn dữ liệu khi test
  final InsightsRepository? repository;

  static const String path = '/insights';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        InsightsCubit(repository: repository ?? InsightsRepository())..load(),
    child: const TResponsiveLayout(mobile: InsightsMobileView()),
  );
}
