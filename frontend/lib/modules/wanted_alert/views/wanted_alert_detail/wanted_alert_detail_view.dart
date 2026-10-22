import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/wanted_alert_detail/wanted_alert_detail_cubit.dart';
import '../../models/wanted_alert_item.dart';
import '../../repositories/wanted_alert_repository.dart';
import 'wanted_alert_detail_mobile_view.dart';

/// Route `/wanted-alerts/:id`: tiêu chí một thông báo và các tin đã khớp.
/// [alert] là thông báo vừa bấm ở trang quản lý (tuỳ chọn, để hiện ngay).
/// Đóng trang trả về true nếu người dùng đã xoá thông báo.
class WantedAlertDetailView extends StatelessWidget {
  final String alertId;
  final WantedAlertItem? alert;

  const WantedAlertDetailView({super.key, required this.alertId, this.alert});

  static const String path = '/wanted-alerts/:id';

  static String location(String alertId) => '/wanted-alerts/$alertId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WantedAlertDetailCubit(
        repository: AppEnvironment.useMockData
            ? MockWantedAlertRepository()
            : ApiWantedAlertRepository(),
        alertId: alertId,
        alert: alert,
      )..start(),
      child: const TResponsiveLayout(mobile: WantedAlertDetailMobileView()),
    );
  }
}
