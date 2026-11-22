import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/repositories/listing_filter_options_repository.dart';

import 'listing_filter_state.dart';

/// Sheet Bộ lọc đầy đủ: chỉnh nháp trên bản sao bộ lọc của trang,
/// trang chỉ tải lại khi người dùng bấm Áp dụng
class ListingFilterCubit extends Cubit<ListingFilterState> {
  ListingFilterCubit({
    required ListingFilterOptionsRepository repository,
    required ListingFilter initial,
    required ListingFilter defaults,
  }) : _repository = repository,
       super(ListingFilterState(draft: initial, defaults: defaults));

  final ListingFilterOptionsRepository _repository;

  @override
  void emit(ListingFilterState state) {
    // Bỏ qua kết quả về muộn sau khi sheet đã đóng
    if (!isClosed) super.emit(state);
  }

  Future<void> loadOptions() async {
    emit(state.copyWith(optionsStatus: ListingFilterOptionsStatus.loading));
    try {
      final options = await _repository.getOptions();
      emit(
        state.copyWith(
          options: options,
          optionsStatus: ListingFilterOptionsStatus.ready,
        ),
      );
    } catch (_) {
      emit(state.copyWith(optionsStatus: ListingFilterOptionsStatus.failure));
    }
  }

  /// null là "Tất cả danh mục"; đổi danh mục thì bỏ danh mục con và
  /// bộ lọc thuộc tính cũ
  void selectCategory(String? id) => _update(state.draft.withCategory(id));

  /// null là mọi danh mục con
  void selectSubcategory(String? id) =>
      _update(state.draft.withSubcategory(id));

  void toggleAttributeValue(String key, String value) =>
      _update(state.draft.toggleAttributeValue(key, value));

  void setAttributeRange(String key, {num? min, num? max}) => _update(
    state.draft.withAttribute(key, AttributeFilterValue(min: min, max: max)),
  );

  void setPrice({required int? min, required int? max}) =>
      _update(state.draft.copyWith(minPrice: () => min, maxPrice: () => max));

  /// Chọn nhóm tình trạng; bấm lại nhóm đang chọn thì bỏ
  void selectConditionGroup(ListingConditionGroup group) => _update(
    state.draft.withConditionGroup(
      state.draft.conditionGroup == group ? null : group,
    ),
  );

  void toggleSeller(ListingSellerKind kind) =>
      _update(state.draft.toggleSeller(kind));

  /// Chip chọn một / danh sách: một giá trị (null hoặc chọn lại là bỏ)
  void selectAttributeValue(String key, String? value) =>
      _update(state.draft.selectAttributeValue(key, value));

  void setRadius(double km) => _update(state.draft.copyWith(radiusKm: km));

  void reset() => _update(state.draft.resetTo(state.defaults));

  void _update(ListingFilter draft) => emit(state.copyWith(draft: draft));
}
