import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
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

  /// null là "Tất cả danh mục"
  void selectCategory(String? id) =>
      _update(state.draft.copyWith(categoryId: () => id));

  void setPrice({required int? min, required int? max}) =>
      _update(state.draft.copyWith(minPrice: () => min, maxPrice: () => max));

  void toggleCondition(ListingCondition condition) =>
      _update(state.draft.toggleCondition(condition));

  void toggleDeal(ListingDealType type) =>
      _update(state.draft.toggleDeal(type));

  void setRadius(double km) => _update(state.draft.copyWith(radiusKm: km));

  void reset() => _update(state.draft.resetTo(state.defaults));

  void _update(ListingFilter draft) => emit(state.copyWith(draft: draft));
}
