import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/services/device_location_service.dart';

import '../../bloc/nearby_cubit.dart';
import '../../repositories/nearby_repository.dart';
import 'nearby_mobile_view.dart';

/// Route `/nearby`: tin đăng quanh vị trí người dùng
class NearbyView extends StatelessWidget {
  const NearbyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NearbyCubit(
        nearbyRepository: AppEnvironment.useMockData
            ? MockNearbyRepository()
            : ApiNearbyRepository(),
        locationRepository: AppEnvironment.useMockData
            ? MockLocationRepository()
            : ApiLocationRepository(),
        locationService: DeviceLocationService(),
      )..start(),
      child: const TResponsiveLayout(mobile: NearbyMobileView()),
    );
  }
}
