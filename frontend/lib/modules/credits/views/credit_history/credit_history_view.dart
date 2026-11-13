import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/credit_history/credit_history_cubit.dart';
import '../../repositories/credit_repository.dart';
import 'credit_history_mobile_view.dart';

/// Route `/credits/history`: sổ cái xu, lọc nạp / đã dùng / hoàn
class CreditHistoryView extends StatelessWidget {
  const CreditHistoryView({super.key, this.repository});

  static const String path = '/credits/history';

  final CreditRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        this.repository ??
        (AppEnvironment.useMockData
            ? MockCreditRepository()
            : ApiCreditRepository());
    return BlocProvider(
      create: (_) => CreditHistoryCubit(repository: repository)..load(),
      child: const TResponsiveLayout(mobile: CreditHistoryMobileView()),
    );
  }
}
