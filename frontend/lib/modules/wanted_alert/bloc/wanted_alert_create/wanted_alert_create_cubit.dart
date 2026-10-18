import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/enums/wanted_alert_match_level.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/repositories/listing_filter_options_repository.dart';

import '../../models/wanted_alert_draft.dart';
import '../../models/wanted_alert_item.dart';
import '../../models/wanted_alert_match.dart';
import '../../repositories/wanted_alert_repository.dart';
import 'wanted_alert_create_state.dart';

/// Trang tạo thông báo "Báo khi có hàng": gõ món cần tìm, xem tin đang có
/// gần giống (bấm vào tin là xong), chưa ưng thì soạn thông báo để được báo
/// khi có tin mới. Tin gợi ý tự cập nhật theo từ khoá và tiêu chí.
class WantedAlertCreateCubit extends Cubit<WantedAlertCreateState> {
  WantedAlertCreateCubit({
    required WantedAlertRepository repository,
    required ListingFilterOptionsRepository filterOptionsRepository,
    String initialKeywords = '',
    this.previewDelay = const Duration(milliseconds: 350),
  }) : _repository = repository,
       _filterOptionsRepository = filterOptionsRepository,
       super(
         WantedAlertCreateState(
           draft: WantedAlertDraft(keywords: initialKeywords),
         ),
       );

  final WantedAlertRepository _repository;
  final ListingFilterOptionsRepository _filterOptionsRepository;

  /// Chờ người dùng ngừng gõ rồi mới tìm tin gợi ý
  final Duration previewDelay;

  Timer? _previewTimer;
  int _previewRequestId = 0;

  @override
  void emit(WantedAlertCreateState state) {
    if (!isClosed) super.emit(state);
  }

  @override
  Future<void> close() {
    _previewTimer?.cancel();
    return super.close();
  }

  Future<void> start() async {
    if (state.draft.hasKeywords) _schedulePreview(immediate: true);
    try {
      final options = await _filterOptionsRepository.getOptions();
      emit(state.copyWith(categories: options.categories));
    } catch (_) {
      // Thiếu tên danh mục thì chỉ ẩn tên, không chặn việc tạo thông báo
    }
  }

  void keywordsChanged(String keywords) {
    if (keywords == state.draft.keywords) return;
    _update(state.draft.copyWith(keywords: keywords));
  }

  /// Nhận bộ lọc từ sheet Bộ lọc (bỏ qua sắp xếp)
  void applyFilter(ListingFilter filter) =>
      _update(state.draft.copyWith(filter: filter));

  void toggleDeal(ListingDealType type) => _update(
    state.draft.copyWith(filter: state.draft.filter.toggleDeal(type)),
  );

  void clearFilters() => applyFilter(WantedAlertCreateState.defaultFilter);

  /// null là toàn quốc
  void setArea(AreaOption? area) =>
      _update(state.draft.copyWith(area: () => area));

  void setMatchLevel(WantedAlertMatchLevel level) {
    if (level == state.draft.matchLevel) return;
    _update(state.draft.copyWith(matchLevel: level));
  }

  /// Bỏ qua phần gợi ý, sang soạn thông báo
  void compose() => emit(state.copyWith(step: WantedAlertCreateStep.compose));

  void backToSearch() =>
      emit(state.copyWith(step: WantedAlertCreateStep.search));

  void retryPreview() => _schedulePreview(immediate: true);

  /// Lưu thông báo; trả về thông báo vừa tạo, null khi lỗi hoặc thiếu
  /// từ khoá
  Future<WantedAlertItem?> submit() async {
    if (!state.draft.hasKeywords || state.isSubmitting) return null;
    emit(state.copyWith(isSubmitting: true));
    try {
      final item = await _repository.create(state.draft);
      emit(state.copyWith(isSubmitting: false));
      return item;
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
      return null;
    }
  }

  /// Đổi trạng thái lưu tin ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> toggleFavorite(WantedAlertMatch match) async {
    final favorite = !match.item.isFavorite;
    syncFavorite(match.listingId, favorite);
    try {
      await _repository.setFavorite(match.listingId, favorite);
    } catch (_) {
      syncFavorite(match.listingId, !favorite);
    }
  }

  void syncFavorite(String listingId, bool favorite) => emit(
    state.copyWith(
      suggestions: [
        for (final match in state.suggestions)
          match.listingId == listingId
              ? match.copyWith(item: match.item.copyWith(isFavorite: favorite))
              : match,
      ],
    ),
  );

  void _update(WantedAlertDraft draft) {
    emit(state.copyWith(draft: draft));
    _schedulePreview();
  }

  void _schedulePreview({bool immediate = false}) {
    _previewTimer?.cancel();
    if (!state.draft.hasKeywords) {
      _previewRequestId++;
      emit(
        state.copyWith(
          previewStatus: WantedAlertPreviewStatus.idle,
          suggestions: const [],
        ),
      );
      return;
    }
    emit(state.copyWith(previewStatus: WantedAlertPreviewStatus.loading));
    if (immediate) {
      _preview();
    } else {
      _previewTimer = Timer(previewDelay, _preview);
    }
  }

  Future<void> _preview() async {
    final requestId = ++_previewRequestId;
    try {
      final suggestions = await _repository.preview(state.draft);
      if (requestId != _previewRequestId) return;
      emit(
        state.copyWith(
          previewStatus: WantedAlertPreviewStatus.ready,
          suggestions: suggestions,
        ),
      );
    } catch (_) {
      if (requestId != _previewRequestId) return;
      emit(state.copyWith(previewStatus: WantedAlertPreviewStatus.failure));
    }
  }
}
