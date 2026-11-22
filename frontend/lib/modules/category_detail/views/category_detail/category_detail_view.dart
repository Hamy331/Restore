import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/data/models/category_model.dart';

import 'package:restore/modules/location/utils/listing_area.dart';

import '../../bloc/category_detail_cubit.dart';
import '../../bloc/category_detail_state.dart';
import '../../repositories/category_listings_repository.dart';
import 'category_detail_mobile_view.dart';

/// Route `/categories/:id`: tin đăng thuộc một danh mục.
/// [category] là danh mục vừa bấm (tuỳ chọn); thiếu thì trang tự tải.
class CategoryDetailView extends StatelessWidget {
  final String categoryId;
  final CategoryModel? category;

  /// Danh mục con mở sẵn (`?sub=`), VD gợi ý "Điện thoại" trong ô tìm kiếm
  final String? subcategoryId;

  const CategoryDetailView({
    super.key,
    required this.categoryId,
    this.category,
    this.subcategoryId,
  });

  static const String path = '/categories/:id';

  /// Đường dẫn mở trang của danh mục [categoryId]
  static String location(String categoryId, {String? subcategoryId}) => Uri(
    path: '/categories/$categoryId',
    queryParameters: subcategoryId == null ? null : {'sub': subcategoryId},
  ).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryDetailCubit(
        repository: AppEnvironment.useMockData
            ? MockCategoryListingsRepository()
            : ApiCategoryListingsRepository(),
        categoryId: categoryId,
        category: category,
        filter: CategoryDetailState.defaultFilterFor(
          categoryId,
        ).withUserArea(context).withSubcategory(subcategoryId),
      )..start(),
      child: const TResponsiveLayout(
        mobile: CategoryDetailMobileView(),
        desktop: CategoryDetailMobileView(wide: true),
      ),
    );
  }
}
