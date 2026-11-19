import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';

import '../models/plan_package.dart';
import '../repositories/plans_repository.dart';
import '../utils/plan_session.dart';
import 'plans_state.dart';

/// Trang Gói tài khoản: gói bán được, gói đang dùng, chuyên mục để chọn
class PlansCubit extends Cubit<PlansState> with SafeEmit<PlansState> {
  PlansCubit({
    PlansRepository? repository,
    CategoryRepository? categoryRepository,
  }) : repository = repository ?? PlansRepository(),
       _categoryRepository = categoryRepository ?? ApiCategoryRepository(),
       super(const PlansState());

  final PlansRepository repository;
  final CategoryRepository _categoryRepository;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) emit(state.copyWith(status: PlansStatus.loading));
    try {
      final results = await Future.wait([
        repository.packages(),
        repository.current(),
        _categoryRepository.getCategories().catchError(
          (_) => <CategoryModel>[],
        ),
      ]);
      final current = results[1] as CurrentPlan;
      PlanSession.apply(current);
      emit(
        state.copyWith(
          status: PlansStatus.ready,
          packages: results[0] as List<PlanPackage>,
          current: current,
          categories: results[2] as List<CategoryModel>,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: PlansStatus.failure));
    }
  }

  /// Trả xu và kích hoạt gói, xong thì tải lại. Lỗi nghiệp vụ ném
  /// [PlanActionException].
  Future<void> subscribe(String packageId, {String? categoryId}) async {
    await repository.subscribe(packageId, categoryId: categoryId);
    await load(showLoading: false);
  }
}
