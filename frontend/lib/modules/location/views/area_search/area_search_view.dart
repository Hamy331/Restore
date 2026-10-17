import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/area_search/area_search_cubit.dart';
import '../../repositories/area_search_repository.dart';
import 'area_search_mobile_view.dart';

/// Route `/nearby/area`: chọn khu vực để xem tin quanh đó.
/// Đóng trang trả về `AreaPickResult` (null nếu người dùng quay lại).
class AreaSearchView extends StatelessWidget {
  const AreaSearchView({super.key});

  static const String path = '/nearby/area';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AreaSearchCubit(
        repository: AppEnvironment.useMockData
            ? MockAreaSearchRepository()
            : ApiAreaSearchRepository(),
      )..start(),
      child: const TResponsiveLayout(mobile: AreaSearchMobileView()),
    );
  }
}
