import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/boost_listing_cubit.dart';
import '../../repositories/promotion_repository.dart';
import 'boost_listing_mobile_view.dart';

/// Route `/boost/:id`: quảng bá một tin của tôi (đẩy tin 24 giờ, Hot sale
/// 1/3/7 ngày) bằng xu. Đóng trang trả về true khi đã đẩy / mua Hot sale.
class BoostListingView extends StatelessWidget {
  const BoostListingView({super.key, required this.listingId, this.repository});

  final String listingId;

  /// Thay nguồn dữ liệu khi test
  final PromotionRepository? repository;

  static const String path = '/boost/:id';

  static String location(String listingId) =>
      '/boost/${Uri.encodeComponent(listingId)}';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BoostListingCubit(
      listingId: listingId,
      repository: repository ?? PromotionRepository(),
    )..load(),
    child: const TResponsiveLayout(mobile: BoostListingMobileView()),
  );
}
