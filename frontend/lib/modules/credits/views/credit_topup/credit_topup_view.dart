import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/credit_topup/credit_topup_cubit.dart';
import '../../repositories/credit_repository.dart';
import 'credit_topup_mobile_view.dart';

/// Route `/credits/topup`: chọn gói → xác nhận → trả tiền → kết quả.
/// `?package=p20` chọn sẵn gói; `?need=10` chọn sẵn gói nhỏ nhất có từ 10 xu
/// trở lên (khi đăng tin thiếu xu).
class CreditTopupView extends StatelessWidget {
  const CreditTopupView({
    super.key,
    this.preselectId,
    this.need,
    this.repository,
  });

  static const String path = '/credits/topup';

  static String location({String? packageId, int? need}) {
    final query = {
      if (packageId != null) 'package': packageId,
      if (need != null && need > 0) 'need': '$need',
    };
    return query.isEmpty
        ? path
        : Uri(path: path, queryParameters: query).toString();
  }

  final String? preselectId;

  /// Số xu còn thiếu, để chọn sẵn gói nhỏ nhất đủ dùng
  final int? need;
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
            ..load(preselectId: preselectId, need: need),
      child: const TResponsiveLayout(mobile: CreditTopupMobileView()),
    );
  }
}
