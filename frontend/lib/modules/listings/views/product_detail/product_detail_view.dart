import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/data/models/listing_model.dart';

import '../../bloc/product_detail/product_detail_cubit.dart';
import '../../repositories/product_detail_repository.dart';
import 'product_detail_mobile_view.dart';

/// Route `/listings/:id`. [preview] là tin từ thẻ vừa bấm (truyền qua
/// `extra`) để hiện ngay ảnh bìa trong lúc tải chi tiết.
class ProductDetailView extends StatelessWidget {
  final String listingId;
  final ListingModel? preview;

  const ProductDetailView({super.key, required this.listingId, this.preview});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(
        listingId: listingId,
        preview: preview,
        repository: AppEnvironment.useMockData
            ? MockProductDetailRepository()
            : ApiProductDetailRepository(),
      )..load(),
      child: const TResponsiveLayout(mobile: ProductDetailMobileView()),
    );
  }
}
