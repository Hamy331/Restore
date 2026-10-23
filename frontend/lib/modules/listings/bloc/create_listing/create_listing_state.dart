import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import '../../models/listing_draft.dart';
import '../../models/posting_quota.dart';
import '../../utils/listing_validator.dart';

enum RequestStatus { idle, loading, success, failure }

class CreateListingState extends Equatable {
  final List<CategoryModel> categories;
  final RequestStatus categoriesStatus;

  /// Hạn mức đăng tin; null khi chưa tải xong hoặc tải lỗi (khi đó app
  /// không chặn, backend vẫn kiểm tra lúc đăng)
  final PostingQuota? quota;
  final ListingDraft draft;
  final bool showBasicInfoErrors;
  final bool showDetailErrors;
  final RequestStatus saveDraftStatus;
  final RequestStatus publishStatus;

  /// Tăng mỗi lần bấm Đăng tin khi còn thiếu thông tin để view báo lỗi
  final int invalidPublishAttempts;

  /// Tăng mỗi lần bị chặn vì chuyên mục đã đủ số tin để view mở thông báo
  final int postingLimitHits;

  const CreateListingState({
    this.categories = const [],
    this.categoriesStatus = RequestStatus.idle,
    this.quota,
    this.draft = const ListingDraft(),
    this.showBasicInfoErrors = false,
    this.showDetailErrors = false,
    this.saveDraftStatus = RequestStatus.idle,
    this.publishStatus = RequestStatus.idle,
    this.invalidPublishAttempts = 0,
    this.postingLimitHits = 0,
  });

  CategoryModel? get category {
    for (final category in categories) {
      if (category.id == draft.categoryId) return category;
    }
    return null;
  }

  /// Hạn mức của chuyên mục đang chọn
  CategoryPostingQuota? get categoryQuota {
    if (draft.categoryId.isEmpty) return null;
    return quota?.forCategory(draft.categoryId);
  }

  Set<ListingField> get basicInfoErrors =>
      showBasicInfoErrors ? ListingValidator.basicInfoErrors(draft) : const {};

  Map<String, AttributeError> get detailErrors => showDetailErrors
      ? ListingValidator.detailErrors(draft, category)
      : const {};

  bool get isBasicInfoValid => ListingValidator.isBasicInfoValid(draft);
  bool get isReadyToPublish =>
      ListingValidator.isReadyToPublish(draft, category);

  CreateListingState copyWith({
    List<CategoryModel>? categories,
    RequestStatus? categoriesStatus,
    PostingQuota? quota,
    ListingDraft? draft,
    bool? showBasicInfoErrors,
    bool? showDetailErrors,
    RequestStatus? saveDraftStatus,
    RequestStatus? publishStatus,
    int? invalidPublishAttempts,
    int? postingLimitHits,
  }) {
    return CreateListingState(
      categories: categories ?? this.categories,
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      quota: quota ?? this.quota,
      draft: draft ?? this.draft,
      showBasicInfoErrors: showBasicInfoErrors ?? this.showBasicInfoErrors,
      showDetailErrors: showDetailErrors ?? this.showDetailErrors,
      saveDraftStatus: saveDraftStatus ?? this.saveDraftStatus,
      publishStatus: publishStatus ?? this.publishStatus,
      invalidPublishAttempts:
          invalidPublishAttempts ?? this.invalidPublishAttempts,
      postingLimitHits: postingLimitHits ?? this.postingLimitHits,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    categoriesStatus,
    quota,
    draft,
    showBasicInfoErrors,
    showDetailErrors,
    saveDraftStatus,
    publishStatus,
    invalidPublishAttempts,
    postingLimitHits,
  ];
}
