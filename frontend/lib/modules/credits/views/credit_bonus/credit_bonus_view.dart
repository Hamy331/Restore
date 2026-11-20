import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/credit_bonus/credit_bonus_cubit.dart';
import '../../repositories/credit_repository.dart';
import 'credit_bonus_mobile_view.dart';

/// Route `/credits/bonus`: xu tặng còn trong ví theo từng lần tặng và hạn dùng
class CreditBonusView extends StatelessWidget {
  const CreditBonusView({super.key, this.repository});

  static const String path = '/credits/bonus';

  /// Truyền vào trong test; mặc định theo [AppEnvironment.useMockData]
  final CreditRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        this.repository ??
        (AppEnvironment.useMockData
            ? MockCreditRepository()
            : ApiCreditRepository());
    return BlocProvider(
      create: (_) => CreditBonusCubit(repository: repository)..load(),
      child: const TResponsiveLayout(mobile: CreditBonusMobileView()),
    );
  }
}
