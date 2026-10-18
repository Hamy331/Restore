import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/area_search/area_search_cubit.dart';
import '../../repositories/area_search_repository.dart';
import 'area_search_mobile_view.dart';

/// Route `/nearby/area`: chọn khu vực để xem tin quanh đó.
/// Đóng trang trả về `AreaPickResult` (null nếu người dùng quay lại).
/// [allowNationwide] (query `nationwide=1`): thay lựa chọn "Gần tôi" bằng
/// "Toàn quốc", dùng khi chọn khu vực cho thông báo "Báo khi có hàng".
class AreaSearchView extends StatelessWidget {
  final bool allowNationwide;

  const AreaSearchView({super.key, this.allowNationwide = false});

  static const String path = '/nearby/area';

  static String location({bool allowNationwide = false}) => Uri(
    path: path,
    queryParameters: allowNationwide ? {'nationwide': '1'} : null,
  ).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AreaSearchCubit(
        repository: AppEnvironment.useMockData
            ? MockAreaSearchRepository()
            : ApiAreaSearchRepository(),
      )..start(),
      child: TResponsiveLayout(
        mobile: AreaSearchMobileView(allowNationwide: allowNationwide),
      ),
    );
  }
}
