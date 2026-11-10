import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import '../../models/draft_quota.dart';
import '../../models/listing_draft.dart';
import '../../models/posting_quota.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/listings_repository.dart';
import '../../repositories/posting_quota_repository.dart';
import 'create_listing_event.dart';
import 'create_listing_state.dart';
import 'package:restore/core/blocs/safe_emit.dart';

class CreateListingBloc extends Bloc<CreateListingEvent, CreateListingState>
    with SafeEmit<CreateListingState> {
  CreateListingBloc({
    required ListingsRepository listingsRepository,
    required CategoryRepository categoryRepository,
    required PostingQuotaRepository postingQuotaRepository,
  }) : _repository = listingsRepository,
       _categoryRepository = categoryRepository,
       _quotaRepository = postingQuotaRepository,
       super(const CreateListingState()) {
    on<CategoriesRequested>(_onCategoriesRequested);
    on<PostingQuotaRequested>(_onPostingQuotaRequested);
    on<CategorySelected>(_onCategorySelected);
    on<PhotosAdded>(_onPhotosAdded);
    on<PhotoRemoved>(_onPhotoRemoved);
    on<CoverPhotoSet>(_onCoverPhotoSet);
    on<DescriptionChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(description: event.description),
      ),
    );
    on<TitleChanged>(
      (event, emit) =>
          _updateDraft(emit, (draft) => draft.copyWith(title: event.title)),
    );
    on<TradeTypeChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(tradeType: event.tradeType),
      ),
    );
    on<PriceChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(price: () => event.price),
      ),
    );
    on<NegotiableChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(isNegotiable: event.isNegotiable),
      ),
    );
    on<ExchangeWishChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(exchangeWish: event.exchangeWish),
      ),
    );
    on<AddressChanged>(
      (event, emit) =>
          _updateDraft(emit, (draft) => draft.copyWith(address: event.address)),
    );
    on<ConditionChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(condition: event.condition),
      ),
    );
    on<AttributeChanged>(_onAttributeChanged);
    on<BasicInfoSubmitted>(
      (event, emit) => emit(state.copyWith(showBasicInfoErrors: true)),
    );
    on<DraftSaveRequested>(_onDraftSaveRequested);
    on<PublishRequested>(_onPublishRequested);
    on<DraftsRequested>(_onDraftsRequested);
    on<DraftOpened>(_onDraftOpened);
    on<DraftDeleted>(_onDraftDeleted);
  }

  final ListingsRepository _repository;
  final CategoryRepository _categoryRepository;
  final PostingQuotaRepository _quotaRepository;

  void _updateDraft(
    Emitter<CreateListingState> emit,
    ListingDraft Function(ListingDraft draft) update,
  ) {
    emit(state.copyWith(draft: update(state.draft)));
  }

  Future<void> _onCategoriesRequested(
    CategoriesRequested event,
    Emitter<CreateListingState> emit,
  ) async {
    if (state.categoriesStatus == RequestStatus.loading) return;
    emit(state.copyWith(categoriesStatus: RequestStatus.loading));
    try {
      final categories = await _categoryRepository.getCategories();
      emit(
        state.copyWith(
          categories: categories,
          categoriesStatus: RequestStatus.success,
        ),
      );
    } catch (_) {
      emit(state.copyWith(categoriesStatus: RequestStatus.failure));
    }
  }

  Future<void> _onPostingQuotaRequested(
    PostingQuotaRequested event,
    Emitter<CreateListingState> emit,
  ) async {
    try {
      final quota = await _quotaRepository.getQuota();
      // Loại người bán theo tài khoản, không để người dùng tự chọn
      emit(
        state.copyWith(
          quota: quota,
          draft: state.draft.copyWith(sellerType: quota.accountType),
        ),
      );
    } catch (_) {
      // Không tải được hạn mức thì vẫn cho đăng, backend sẽ kiểm tra
    } finally {
      if (!(event.done?.isCompleted ?? true)) event.done!.complete();
    }
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<CreateListingState> emit,
  ) {
    if (event.categoryId == state.draft.categoryId) return;
    // Mỗi danh mục có bộ thông tin chi tiết riêng nên cần làm mới
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          categoryId: event.categoryId,
          attributes: const {},
        ),
        showDetailErrors: false,
      ),
    );
  }

  void _onPhotosAdded(PhotosAdded event, Emitter<CreateListingState> emit) {
    final images = [
      ...state.draft.images,
      ...event.paths.where((path) => !state.draft.images.contains(path)),
    ].take(ListingDraft.maxImages).toList();
    _updateDraft(emit, (draft) => draft.copyWith(images: images));
  }

  void _onPhotoRemoved(PhotoRemoved event, Emitter<CreateListingState> emit) {
    final images = [...state.draft.images]..removeAt(event.index);
    _updateDraft(emit, (draft) => draft.copyWith(images: images));
  }

  void _onCoverPhotoSet(CoverPhotoSet event, Emitter<CreateListingState> emit) {
    if (event.index == 0) return;
    final images = [...state.draft.images];
    images.insert(0, images.removeAt(event.index));
    _updateDraft(emit, (draft) => draft.copyWith(images: images));
  }

  void _onAttributeChanged(
    AttributeChanged event,
    Emitter<CreateListingState> emit,
  ) {
    final attributes = {...state.draft.attributes, event.key: event.value};
    _updateDraft(emit, (draft) => draft.copyWith(attributes: attributes));
  }

  Future<void> _onDraftSaveRequested(
    DraftSaveRequested event,
    Emitter<CreateListingState> emit,
  ) async {
    if (state.saveDraftStatus == RequestStatus.loading) return;
    // Đã giữ đủ số tin nháp của gói: báo ngay, không gọi API
    if (state.savingAddsDraft && (state.draftQuota?.isFull ?? false)) {
      emit(
        state.copyWith(
          saveDraftStatus: RequestStatus.idle,
          draftLimitHits: state.draftLimitHits + 1,
        ),
      );
      return;
    }
    emit(state.copyWith(saveDraftStatus: RequestStatus.loading));
    final sent = state.draft;
    try {
      final saved = await _repository.saveDraft(sent, state.category);
      // Chỉ lấy id (và URL ảnh nếu bộ ảnh chưa đổi) để không ghi đè
      // những gì người dùng vừa nhập trong lúc chờ lưu
      final imagesUnchanged = state.draft.images == sent.images;
      emit(
        state.copyWith(
          draft: state.draft.copyWith(
            id: saved.id,
            status: saved.status,
            images: imagesUnchanged ? saved.images : null,
          ),
          savedDraft: saved,
          saveDraftStatus: RequestStatus.success,
        ),
      );
      add(const DraftsRequested());
    } on ListingSaveException catch (error) {
      debugPrint('Lưu nháp lỗi: $error');
      if (!error.isDraftLimitReached) {
        // Giữ id và ảnh đã tải để lần lưu sau sửa đúng tin này, không tạo
        // nháp trùng và không tải lại ảnh
        emit(
          state.copyWith(
            draft: _keepProgress(sent, error),
            saveDraftStatus: RequestStatus.failure,
            saveError: error,
          ),
        );
        if (error.draft.id != null && sent.id == null) {
          add(const DraftsRequested());
        }
        return;
      }
      // Số tin nháp trên máy đã cũ (VD lưu từ thiết bị khác): tải lại rồi báo
      emit(
        state.copyWith(
          saveDraftStatus: RequestStatus.idle,
          draftLimitHits: state.draftLimitHits + 1,
        ),
      );
      add(const DraftsRequested());
    } catch (error) {
      emit(
        state.copyWith(
          saveDraftStatus: RequestStatus.failure,
          saveError: error,
        ),
      );
    }
  }

  /// Bản đang soạn kèm phần đã lưu được trước khi lỗi: id, trạng thái và ảnh
  /// đã tải (chỉ lấy ảnh khi người dùng chưa đổi bộ ảnh trong lúc chờ)
  ListingDraft _keepProgress(ListingDraft sent, ListingSaveException error) {
    final saved = error.draft;
    final imagesUnchanged = state.draft.images == sent.images;
    final kept = state.draft.copyWith(
      id: saved.id,
      status: saved.status,
      images: imagesUnchanged && saved.images.length == sent.images.length
          ? saved.images
          : null,
    );
    // Ảnh không còn trên máy thì bỏ khỏi tin để người dùng chọn lại
    final missing = error.imagePaths;
    if (missing.isEmpty) return kept;
    return kept.copyWith(
      images: [
        for (final image in kept.images)
          if (!missing.contains(image)) image,
      ],
    );
  }

  Future<void> _onPublishRequested(
    PublishRequested event,
    Emitter<CreateListingState> emit,
  ) async {
    if (state.publishStatus == RequestStatus.loading) return;
    if (!state.isReadyToPublish) {
      emit(
        state.copyWith(
          showBasicInfoErrors: true,
          showDetailErrors: true,
          invalidPublishAttempts: state.invalidPublishAttempts + 1,
        ),
      );
      return;
    }

    // Hết suất miễn phí: hỏi người dùng có trả xu không trước khi gửi
    if (!event.payWithCredits &&
        (state.quota?.isFull(state.draft.categoryId) ?? false)) {
      emit(state.copyWith(postingLimitHits: state.postingLimitHits + 1));
      return;
    }

    emit(state.copyWith(publishStatus: RequestStatus.loading));
    final sent = state.draft;
    try {
      final published = await _repository.publish(
        sent,
        state.category,
        payWithCredits: event.payWithCredits,
        allowDuplicate: event.allowDuplicate,
      );
      emit(
        state.copyWith(draft: published, publishStatus: RequestStatus.success),
      );
      add(const PostingQuotaRequested());
    } on ListingSaveException catch (error) {
      debugPrint('Đăng tin lỗi: $error');
      final duplicate = error.duplicate;
      if (duplicate != null) {
        emit(
          state.copyWith(
            draft: _keepProgress(sent, error),
            publishStatus: RequestStatus.idle,
            duplicate: duplicate,
            duplicatePaid: event.payWithCredits,
            duplicateHits: state.duplicateHits + 1,
          ),
        );
        return;
      }
      if (!error.isPostingLimitReached) {
        // Tin đã tạo trên máy chủ: thử lại thì cập nhật đúng tin đó
        emit(
          state.copyWith(
            draft: _keepProgress(sent, error),
            publishStatus: RequestStatus.failure,
            saveError: error,
          ),
        );
        return;
      }
      // Hạn mức trên máy đã cũ (VD đăng từ thiết bị khác) hoặc ví không đủ
      // xu: tải lại hạn mức và số dư trước rồi mới báo, để sheet hiện đúng
      PostingQuota? fresh;
      try {
        fresh = await _quotaRepository.getQuota();
      } catch (_) {
        fresh = null;
      }
      emit(
        state.copyWith(
          quota: fresh ?? state.quota,
          publishStatus: RequestStatus.idle,
          postingLimitHits: state.postingLimitHits + 1,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(publishStatus: RequestStatus.failure, saveError: error),
      );
    }
  }

  static const String _draftStatus = 'DRAFT';

  Future<void> _onDraftsRequested(
    DraftsRequested event,
    Emitter<CreateListingState> emit,
  ) async {
    if (state.draftsStatus == RequestStatus.loading) return;
    if (event.loadMore && !state.hasMoreDrafts) return;
    final page = event.loadMore
        ? state.drafts.length ~/ _draftsPageSize + 1
        : 1;
    emit(state.copyWith(draftsStatus: RequestStatus.loading));
    // Có tin bị xóa trong lúc đang tải thì số liệu trả về đã cũ
    final deletes = _draftDeletes;
    if (!event.loadMore) {
      try {
        final quota = await _repository.draftQuota();
        if (deletes == _draftDeletes) emit(state.copyWith(draftQuota: quota));
      } catch (_) {
        // Không tải được thì vẫn cho lưu, backend sẽ kiểm tra
      }
    }
    try {
      final result = await _repository.mine(page: page, status: _draftStatus);
      // Bỏ tin đã xóa: kết quả có thể được gửi về trước khi xóa xong
      final items = result.items.where(
        (item) => !_deletedDraftIds.contains(item.id),
      );
      emit(
        state.copyWith(
          drafts: event.loadMore
              ? [
                  ...state.drafts,
                  // Xóa bớt nháp làm lệch trang nên bỏ tin đã có
                  ...items.where(
                    (item) => state.drafts.every((old) => old.id != item.id),
                  ),
                ]
              : items.toList(),
          hasMoreDrafts: result.hasMore,
          draftsStatus: RequestStatus.success,
        ),
      );
    } catch (_) {
      emit(state.copyWith(draftsStatus: RequestStatus.failure));
    }
  }

  static const int _draftsPageSize = 20;

  /// Tin nháp đã xóa (hoặc đang xóa) trong phiên này, để kết quả tải danh
  /// sách về muộn không hiện lại chúng
  final Set<String> _deletedDraftIds = {};

  /// Đếm số lần xóa, để bỏ hạn mức nháp tải về trước khi xóa
  int _draftDeletes = 0;

  Future<void> _onDraftOpened(
    DraftOpened event,
    Emitter<CreateListingState> emit,
  ) async {
    if (state.openDraftStatus == RequestStatus.loading) return;
    emit(
      state.copyWith(
        openDraftStatus: RequestStatus.loading,
        openingDraftId: event.id,
      ),
    );
    try {
      final loaded = await _repository.getDraft(event.id);
      // Tin đã được đăng ở nơi khác thì không còn là nháp để soạn tiếp
      if (loaded.status != ListingStatus.draft) {
        throw StateError('Listing ${event.id} is no longer a draft');
      }
      final draft = state.quota == null
          ? loaded
          : loaded.copyWith(sellerType: state.quota!.accountType);
      emit(
        state.copyWith(
          draft: draft,
          savedDraft: draft,
          showBasicInfoErrors: false,
          showDetailErrors: false,
          publishStatus: RequestStatus.idle,
          saveDraftStatus: RequestStatus.idle,
          openDraftStatus: RequestStatus.success,
        ),
      );
    } catch (_) {
      emit(state.copyWith(openDraftStatus: RequestStatus.failure));
      add(const DraftsRequested());
    }
  }

  Future<void> _onDraftDeleted(
    DraftDeleted event,
    Emitter<CreateListingState> emit,
  ) async {
    // Bấm xóa lần nữa khi tin đang được xóa thì bỏ qua
    if (!_deletedDraftIds.add(event.id)) return;
    _draftDeletes++;
    final before = state.drafts;
    final title = before
        .where((item) => item.id == event.id)
        .map((item) => item.title.trim())
        .firstOrNull;
    // Ẩn ngay cho mượt, lỗi thì trả lại
    emit(
      state.copyWith(
        drafts: [
          for (final item in before)
            if (item.id != event.id) item,
        ],
      ),
    );
    try {
      await _repository.deleteDraft(event.id);
      final quota = state.draftQuota;
      emit(
        state.copyWith(
          draftQuota: quota == null
              ? null
              : DraftQuota(
                  used: (quota.used - 1).clamp(0, quota.limit),
                  limit: quota.limit,
                ),
          draftDeleteSuccesses: state.draftDeleteSuccesses + 1,
          lastDeletedDraftTitle: title ?? '',
        ),
      );
      // Đang soạn đúng tin vừa xóa thì coi như tin mới
      if (state.draft.id == event.id) {
        emit(
          CreateListingState(
            categories: state.categories,
            categoriesStatus: state.categoriesStatus,
            quota: state.quota,
            draft: ListingDraft(sellerType: state.draft.sellerType),
            drafts: state.drafts,
            draftsStatus: state.draftsStatus,
            hasMoreDrafts: state.hasMoreDrafts,
            draftDeleteFailures: state.draftDeleteFailures,
            draftDeleteSuccesses: state.draftDeleteSuccesses,
            lastDeletedDraftTitle: state.lastDeletedDraftTitle,
            draftQuota: state.draftQuota,
            draftLimitHits: state.draftLimitHits,
          ),
        );
      }
    } catch (error) {
      debugPrint('Delete draft ${event.id} failed: $error');
      _deletedDraftIds.remove(event.id);
      emit(
        state.copyWith(
          drafts: before,
          draftDeleteFailures: state.draftDeleteFailures + 1,
        ),
      );
    }
  }

  /// Lưu nháp rồi chờ kết quả (khi thoát luồng hoặc trước khi mở nháp khác).
  /// true khi lưu xong; false khi lỗi hoặc đã đủ số tin nháp (view đã báo).
  Future<bool> saveDraftAndWait() async {
    final hits = state.draftLimitHits;
    // Chỉ lấy kết quả của lần lưu này: sau trạng thái loading của nó (các
    // sự kiện khác như tải danh sách nháp vẫn giữ trạng thái lưu cũ)
    var started = false;
    final result = stream.firstWhere((state) {
      if (state.draftLimitHits != hits) return true;
      if (state.saveDraftStatus == RequestStatus.loading) {
        started = true;
        return false;
      }
      return started &&
          (state.saveDraftStatus == RequestStatus.success ||
              state.saveDraftStatus == RequestStatus.failure);
    });
    add(const DraftSaveRequested());
    final done = await result;
    return done.draftLimitHits == hits &&
        done.saveDraftStatus == RequestStatus.success;
  }
}
