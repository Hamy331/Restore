import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../bloc/product_detail/product_detail_cubit.dart';
import '../../repositories/product_detail_repository.dart';
import 'product_detail_mobile_view.dart';

/// Route `/listings/:id`. [preview] là tin từ thẻ vừa bấm (truyền qua
/// `extra`) để hiện ngay ảnh bìa trong lúc tải chi tiết.
class ProductDetailView extends StatelessWidget {
  final String listingId;
  final ListingModel? preview;
  final bool demoPreview;

  const ProductDetailView({
    super.key,
    required this.listingId,
    this.preview,
    this.demoPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(
        listingId: listingId,
        preview: preview,
        repository: demoPreview || AppEnvironment.useMockData
            ? MockProductDetailRepository()
            : ApiProductDetailRepository(),
      )..load(),
      child: Column(
        children: [
          if (demoPreview)
            SafeArea(
              bottom: false,
              child: Material(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(AppLocalizations.of(context)!.feedSampleListing),
                ),
              ),
            ),
          const Expanded(
            child: TResponsiveLayout(mobile: ProductDetailMobileView()),
          ),
        ],
      ),
    );
  }
}
