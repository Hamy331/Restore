import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';

import '../models/plan_package.dart';

enum PlansStatus { loading, ready, failure }

class PlansState extends Equatable {
  const PlansState({
    this.status = PlansStatus.loading,
    this.packages = const [],
    this.current,
    this.categories = const [],
  });

  final PlansStatus status;

  /// Gói bán được (Bán chuyên, Cửa hàng), gói thấp trước
  final List<PlanPackage> packages;
  final CurrentPlan? current;

  /// Chuyên mục để chọn làm chuyên mục chính khi mua gói
  final List<CategoryModel> categories;

  PlansState copyWith({
    PlansStatus? status,
    List<PlanPackage>? packages,
    CurrentPlan? current,
    List<CategoryModel>? categories,
  }) => PlansState(
    status: status ?? this.status,
    packages: packages ?? this.packages,
    current: current ?? this.current,
    categories: categories ?? this.categories,
  );

  @override
  List<Object?> get props => [status, packages, current, categories];
}
