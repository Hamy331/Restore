import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/listing_draft.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/listings_repository.dart';
import 'create_listing_event.dart';
import 'create_listing_state.dart';

class CreateListingBloc extends Bloc<CreateListingEvent, CreateListingState> {
  CreateListingBloc({
    required ListingsRepository listingsRepository,
    required CategoryRepository categoryRepository,
  }) : _repository = listingsRepository,
       _categoryRepository = categoryRepository,
       super(const CreateListingState()) {
    on<CategoriesRequested>(_onCategoriesRequested);
    on<DraftRequested>((event, emit) async {
      if (state.isBusy) return;
      emit(
        state.copyWith(isLoadingDraft: true, draftLoadFailed: false, error: ''),
      );
      try {
        final draft = await _repository.getDraft(event.id);
        emit(state.copyWith(draft: draft, isLoadingDraft: false));
      } catch (_) {
        emit(
          state.copyWith(
            isLoadingDraft: false,
            draftLoadFailed: true,
            error: 'Không tải được tin của bạn.',
          ),
        );
      }
    });
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
    on<SellerTypeChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(sellerType: event.sellerType),
      ),
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
  }

  final ListingsRepository _repository;
  final CategoryRepository _categoryRepository;

  void _updateDraft(
    Emitter<CreateListingState> emit,
    ListingDraft Function(ListingDraft draft) update,
  ) {
    if (state.isBusy) return;
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

  void _onCategorySelected(
    CategorySelected event,
    Emitter<CreateListingState> emit,
  ) {
    if (state.isBusy) return;
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
    if (state.isBusy ||
        event.index < 0 ||
        event.index >= state.draft.images.length) {
      return;
    }
    final images = [...state.draft.images]..removeAt(event.index);
    _updateDraft(emit, (draft) => draft.copyWith(images: images));
  }

  void _onCoverPhotoSet(CoverPhotoSet event, Emitter<CreateListingState> emit) {
    if (state.isBusy ||
        event.index < 0 ||
        event.index >= state.draft.images.length) {
      return;
    }
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
    if (state.isBusy) return;
    emit(state.copyWith(saveDraftStatus: RequestStatus.loading, error: ''));
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
            updatedAt: saved.updatedAt,
            images: imagesUnchanged ? saved.images : null,
          ),
          saveDraftStatus: RequestStatus.success,
        ),
      );
    } on ListingSaveException catch (error) {
      emit(
        state.copyWith(
          draft: error.draft,
          error: error.message,
          saveDraftStatus: RequestStatus.failure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          error: 'Không lưu được nháp.',
          saveDraftStatus: RequestStatus.failure,
        ),
      );
    }
  }

  Future<void> _onPublishRequested(
    PublishRequested event,
    Emitter<CreateListingState> emit,
  ) async {
    if (state.isBusy) return;
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

    emit(state.copyWith(publishStatus: RequestStatus.loading, error: ''));
    try {
      final published = await _repository.publish(state.draft, state.category);
      emit(
        state.copyWith(draft: published, publishStatus: RequestStatus.success),
      );
    } on ListingSaveException catch (error) {
      emit(
        state.copyWith(
          draft: error.draft,
          error: error.message,
          publishStatus: RequestStatus.failure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          error: 'Không gửi được tin.',
          publishStatus: RequestStatus.failure,
        ),
      );
    }
  }
}
