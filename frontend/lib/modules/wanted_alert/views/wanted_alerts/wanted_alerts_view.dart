import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/wanted_alerts/wanted_alerts_cubit.dart';
import '../../repositories/wanted_alert_repository.dart';
import 'wanted_alerts_mobile_view.dart';

/// Route `/wanted-alerts`: quản lý thông báo "Báo khi có hàng", xem số tin
/// khớp mới của từng thông báo, xoá để dừng thông báo.
class WantedAlertsView extends StatelessWidget {
  const WantedAlertsView({super.key});

  static const String path = '/wanted-alerts';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WantedAlertsCubit(
        repository: AppEnvironment.useMockData
            ? MockWantedAlertRepository()
            : ApiWantedAlertRepository(),
      )..load(),
      child: const TResponsiveLayout(mobile: WantedAlertsMobileView()),
    );
  }
}
