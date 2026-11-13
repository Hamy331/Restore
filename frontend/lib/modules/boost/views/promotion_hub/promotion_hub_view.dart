import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/promotion_hub_cubit.dart';
import '../../repositories/promotion_repository.dart';
import 'promotion_hub_mobile_view.dart';

/// Route `/boost`: trang Boost của tôi (mở từ nút Boost ở menu xoè). Tin
/// đang quảng bá, sắp hết hạn, chưa quảng bá; đẩy tin / gia hạn ngay trên
/// danh sách, bấm tin để mở trang quảng bá chi tiết.
class PromotionHubView extends StatelessWidget {
  const PromotionHubView({super.key, this.repository});

  /// Thay nguồn dữ liệu khi test
  final PromotionRepository? repository;

  static const String path = '/boost';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        PromotionHubCubit(repository: repository ?? PromotionRepository())
          ..load(),
    child: const TResponsiveLayout(mobile: PromotionHubMobileView()),
  );
}
