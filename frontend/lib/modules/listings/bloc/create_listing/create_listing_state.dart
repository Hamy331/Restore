import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/data/models/listing_model.dart';
import '../../models/draft_quota.dart';
import '../../models/listing_draft.dart';
import '../../models/posting_quota.dart';
import '../../repositories/listings_repository.dart' show DuplicateListing;
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

  /// Tăng mỗi lần bị chặn vì đã có tin giống vậy ([duplicate]) để view hỏi
  /// kích hoạt lại tin cũ hay vẫn đăng mới
  final int duplicateHits;
  final DuplicateListing? duplicate;

  /// Lần đăng bị chặn vì trùng có kèm trả xu không, để "Vẫn đăng mới" giữ nguyên
  final bool duplicatePaid;

  /// Bản đã lưu gần nhất (lưu nháp hoặc mở từ danh sách nháp), để biết còn
  /// thay đổi chưa lưu khi thoát. null khi chưa lưu lần nào.
  final ListingDraft? savedDraft;

  /// Tin nháp của tài khoản, vừa sửa trước (trang Tin nháp, thẻ ở bước 1)
  final List<ListingModel> drafts;
  final RequestStatus draftsStatus;
  final bool hasMoreDrafts;

  /// Mở một tin nháp để soạn tiếp: [openingDraftId] là tin đang mở
  final RequestStatus openDraftStatus;
  final String? openingDraftId;

  /// Tăng mỗi lần xóa nháp lỗi để view báo
  final int draftDeleteFailures;

  /// Tăng mỗi lần xóa nháp xong để view báo; [lastDeletedDraftTitle] là
  /// tiêu đề tin vừa xóa (rỗng khi tin chưa có tiêu đề)
  final int draftDeleteSuccesses;
  final String lastDeletedDraftTitle;

  /// Số tin nháp đang giữ / giới hạn của gói; null khi chưa tải được
  final DraftQuota? draftQuota;

  /// Tăng mỗi lần lưu nháp bị chặn vì đã đủ số tin nháp để view báo
  final int draftLimitHits;

  /// Lỗi của lần lưu nháp / đăng tin gần nhất để view báo đúng nguyên nhân
  final Object? saveError;

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
    this.duplicateHits = 0,
    this.duplicate,
    this.duplicatePaid = false,
    this.savedDraft,
    this.drafts = const [],
    this.draftsStatus = RequestStatus.idle,
    this.hasMoreDrafts = false,
    this.openDraftStatus = RequestStatus.idle,
    this.openingDraftId,
    this.draftDeleteFailures = 0,
    this.draftDeleteSuccesses = 0,
    this.lastDeletedDraftTitle = '',
    this.draftQuota,
    this.draftLimitHits = 0,
    this.saveError,
  });

  /// Lưu nháp lần này sẽ tạo thêm một tin nháp (chưa phải nháp đã lưu)
  bool get savingAddsDraft =>
      draft.id == null || draft.status != ListingStatus.draft;

  /// Đã nhập gì đó mà chưa lưu nháp (hỏi lại trước khi thoát luồng đăng tin)
  bool get hasUnsavedChanges {
    if (publishStatus == RequestStatus.success) return false;
    final saved = savedDraft;
    if (saved == null) return draft.hasContent;
    return !draft.sameContentAs(saved);
  }

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
    int? duplicateHits,
    DuplicateListing? duplicate,
    bool? duplicatePaid,
    ListingDraft? savedDraft,
    List<ListingModel>? drafts,
    RequestStatus? draftsStatus,
    bool? hasMoreDrafts,
    RequestStatus? openDraftStatus,
    String? openingDraftId,
    int? draftDeleteFailures,
    int? draftDeleteSuccesses,
    String? lastDeletedDraftTitle,
    DraftQuota? draftQuota,
    int? draftLimitHits,
    Object? saveError,
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
      duplicateHits: duplicateHits ?? this.duplicateHits,
      duplicate: duplicate ?? this.duplicate,
      duplicatePaid: duplicatePaid ?? this.duplicatePaid,
      savedDraft: savedDraft ?? this.savedDraft,
      drafts: drafts ?? this.drafts,
      draftsStatus: draftsStatus ?? this.draftsStatus,
      hasMoreDrafts: hasMoreDrafts ?? this.hasMoreDrafts,
      openDraftStatus: openDraftStatus ?? this.openDraftStatus,
      openingDraftId: openingDraftId ?? this.openingDraftId,
      draftDeleteFailures: draftDeleteFailures ?? this.draftDeleteFailures,
      draftDeleteSuccesses: draftDeleteSuccesses ?? this.draftDeleteSuccesses,
      lastDeletedDraftTitle:
          lastDeletedDraftTitle ?? this.lastDeletedDraftTitle,
      draftQuota: draftQuota ?? this.draftQuota,
      draftLimitHits: draftLimitHits ?? this.draftLimitHits,
      saveError: saveError ?? this.saveError,
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
    duplicateHits,
    duplicatePaid,
    savedDraft,
    drafts,
    draftsStatus,
    hasMoreDrafts,
    openDraftStatus,
    openingDraftId,
    draftDeleteFailures,
    draftDeleteSuccesses,
    lastDeletedDraftTitle,
    draftQuota,
    draftLimitHits,
    saveError,
  ];
}
