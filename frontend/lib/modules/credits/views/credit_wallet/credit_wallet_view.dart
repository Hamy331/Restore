import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/credit_wallet/credit_wallet_cubit.dart';
import '../../repositories/credit_repository.dart';
import 'credit_wallet_mobile_view.dart';

/// Route `/credits`: ví Xu ReStore, số dư, nút nạp và giao dịch gần đây
class CreditWalletView extends StatelessWidget {
  const CreditWalletView({super.key, this.repository});

  static const String path = '/credits';

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
      create: (_) => CreditWalletCubit(repository: repository)..load(),
      child: const TResponsiveLayout(mobile: CreditWalletMobileView()),
    );
  }
}
