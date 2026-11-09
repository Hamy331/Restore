import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/credit_topup/credit_topup_cubit.dart';
import '../../repositories/credit_repository.dart';
import 'credit_topup_mobile_view.dart';

/// Route `/credits/topup`: chọn gói → xác nhận → trả tiền → kết quả.
/// `?package=p20` chọn sẵn gói (VD gói nhỏ nhất đủ dùng khi đăng tin thiếu xu).
class CreditTopupView extends StatelessWidget {
  const CreditTopupView({super.key, this.preselectId, this.repository});

  static const String path = '/credits/topup';

  static String location({String? packageId}) => packageId == null
      ? path
      : Uri(path: path, queryParameters: {'package': packageId}).toString();

  final String? preselectId;
  final CreditRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        this.repository ??
        (AppEnvironment.useMockData
            ? MockCreditRepository()
            : ApiCreditRepository());
    return BlocProvider(
      create: (_) =>
          CreditTopupCubit(repository: repository)
            ..load(preselectId: preselectId),
      child: const TResponsiveLayout(mobile: CreditTopupMobileView()),
    );
  }
}
