import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import '../../models/listing_draft.dart';
import '../../utils/listing_validator.dart';

enum RequestStatus { idle, loading, success, failure }

class CreateListingState extends Equatable {
  final List<CategoryModel> categories;
  final RequestStatus categoriesStatus;
  final ListingDraft draft;
  final bool showBasicInfoErrors;
  final bool showDetailErrors;
  final RequestStatus saveDraftStatus;
  final RequestStatus publishStatus;

  /// Tăng mỗi lần bấm Đăng tin khi còn thiếu thông tin để view báo lỗi
  final int invalidPublishAttempts;
  final String error;
  final bool isLoadingDraft;
  final bool draftLoadFailed;
  bool get isBusy =>
      isLoadingDraft ||
      saveDraftStatus == RequestStatus.loading ||
      publishStatus == RequestStatus.loading;

  const CreateListingState({
    this.categories = const [],
    this.categoriesStatus = RequestStatus.idle,
    this.draft = const ListingDraft(),
    this.showBasicInfoErrors = false,
    this.showDetailErrors = false,
    this.saveDraftStatus = RequestStatus.idle,
    this.publishStatus = RequestStatus.idle,
    this.invalidPublishAttempts = 0,
    this.error = '',
    this.isLoadingDraft = false,
    this.draftLoadFailed = false,
  });

  CategoryModel? get category {
    for (final category in categories) {
      if (category.id == draft.categoryId) return category;
    }
    return null;
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
    ListingDraft? draft,
    bool? showBasicInfoErrors,
    bool? showDetailErrors,
    RequestStatus? saveDraftStatus,
    RequestStatus? publishStatus,
    int? invalidPublishAttempts,
    String? error,
    bool? isLoadingDraft,
    bool? draftLoadFailed,
  }) {
    return CreateListingState(
      error: error ?? this.error,
      isLoadingDraft: isLoadingDraft ?? this.isLoadingDraft,
      draftLoadFailed: draftLoadFailed ?? this.draftLoadFailed,
      categories: categories ?? this.categories,
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      draft: draft ?? this.draft,
      showBasicInfoErrors: showBasicInfoErrors ?? this.showBasicInfoErrors,
      showDetailErrors: showDetailErrors ?? this.showDetailErrors,
      saveDraftStatus: saveDraftStatus ?? this.saveDraftStatus,
      publishStatus: publishStatus ?? this.publishStatus,
      invalidPublishAttempts:
          invalidPublishAttempts ?? this.invalidPublishAttempts,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    categoriesStatus,
    draft,
    showBasicInfoErrors,
    showDetailErrors,
    saveDraftStatus,
    publishStatus,
    invalidPublishAttempts,
    error,
    isLoadingDraft,
    draftLoadFailed,
  ];
}
