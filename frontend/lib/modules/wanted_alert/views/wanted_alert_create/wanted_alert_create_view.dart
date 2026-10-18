import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/shared/repositories/listing_filter_options_repository.dart';

import '../../bloc/wanted_alert_create/wanted_alert_create_cubit.dart';
import '../../repositories/wanted_alert_repository.dart';
import 'wanted_alert_create_mobile_view.dart';

/// Route `/wanted-alerts/new?q=`: gõ món cần tìm, xem tin đang có gần giống
/// trước, chưa ưng (hoặc bỏ qua) thì soạn thông báo "Báo khi có hàng".
///
/// - [initialKeywords]: điền sẵn, VD mở từ trang kết quả tìm kiếm.
/// - [fromAlerts] (query `from=alerts`): mở từ trang quản lý, tạo xong thì
///   quay lại và trả về thông báo vừa tạo; mở từ nơi khác thì chuyển sang
///   trang quản lý.
class WantedAlertCreateView extends StatelessWidget {
  final String initialKeywords;
  final bool fromAlerts;

  const WantedAlertCreateView({
    super.key,
    this.initialKeywords = '',
    this.fromAlerts = false,
  });

  static const String path = '/wanted-alerts/new';

  static String location({String keywords = '', bool fromAlerts = false}) =>
      Uri(
        path: path,
        queryParameters: {
          if (keywords.isNotEmpty) 'q': keywords,
          if (fromAlerts) 'from': 'alerts',
        },
      ).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WantedAlertCreateCubit(
        repository: AppEnvironment.useMockData
            ? MockWantedAlertRepository()
            : ApiWantedAlertRepository(),
        filterOptionsRepository: AppEnvironment.useMockData
            ? MockListingFilterOptionsRepository()
            : ApiListingFilterOptionsRepository(),
        initialKeywords: initialKeywords,
      )..start(),
      child: TResponsiveLayout(
        mobile: WantedAlertCreateMobileView(
          initialKeywords: initialKeywords,
          fromAlerts: fromAlerts,
        ),
      ),
    );
  }
}
