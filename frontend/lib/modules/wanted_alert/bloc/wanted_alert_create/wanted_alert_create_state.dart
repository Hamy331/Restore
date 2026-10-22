import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../../models/wanted_alert_draft.dart';
import '../../models/wanted_alert_match.dart';

/// Hai bước của trang tạo thông báo
enum WantedAlertCreateStep {
  /// Gõ món cần tìm, xem tin đang có gần giống trước
  search,

  /// Soạn thông báo: từ khoá, tiêu chí, mức độ giống
  compose,
}

enum WantedAlertPreviewStatus {
  /// Chưa gõ đủ từ khoá
  idle,
  loading,
  ready,
  failure,
}

class WantedAlertCreateState extends Equatable {
  /// Bộ lọc mặc định (không lọc gì), dùng cho số đếm trên nút Bộ lọc
  static const ListingFilter defaultFilter = ListingFilter();

  final WantedAlertCreateStep step;
  final WantedAlertDraft draft;
  final WantedAlertPreviewStatus previewStatus;

  /// Tin đang có gần giống [draft], điểm cao trước
  final List<WantedAlertMatch> suggestions;

  /// Danh mục để hiện tên danh mục đã chọn
  final List<CategoryModel> categories;
  final bool isSubmitting;

  const WantedAlertCreateState({
    this.step = WantedAlertCreateStep.search,
    this.draft = const WantedAlertDraft(),
    this.previewStatus = WantedAlertPreviewStatus.idle,
    this.suggestions = const [],
    this.categories = const [],
    this.isSubmitting = false,
  });

  CategoryModel? get selectedCategory {
    final id = draft.filter.categoryId;
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  WantedAlertCreateState copyWith({
    WantedAlertCreateStep? step,
    WantedAlertDraft? draft,
    WantedAlertPreviewStatus? previewStatus,
    List<WantedAlertMatch>? suggestions,
    List<CategoryModel>? categories,
    bool? isSubmitting,
  }) => WantedAlertCreateState(
    step: step ?? this.step,
    draft: draft ?? this.draft,
    previewStatus: previewStatus ?? this.previewStatus,
    suggestions: suggestions ?? this.suggestions,
    categories: categories ?? this.categories,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );

  @override
  List<Object?> get props => [
    step,
    draft,
    previewStatus,
    suggestions,
    categories,
    isSubmitting,
  ];
}
