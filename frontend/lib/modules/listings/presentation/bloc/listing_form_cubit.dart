import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';

import '../../data/listing_repository.dart';

class ListingFormImage {
  const ListingFormImage({this.url, this.bytes, this.contentType});
  final String? url;
  final Uint8List? bytes;
  final String? contentType;
}

class ListingFormState {
  const ListingFormState({
    required this.editing,
    this.listingId = '',
    this.isLoading = false,
    this.isLoaded = true,
    this.step = 1,
    this.condition = 'USED_GOOD',
    this.categoryId = '',
    this.negotiable = true,
    this.title = '',
    this.price = '',
    this.description = '',
    this.error = '',
    this.isSubmitting = false,
    this.createdId = '',
    this.savedId = '',
    this.images = const [],
    this.imagesChanged = false,
    this.listingStatus = 'NEW',
    this.finishedAsDraft = false,
  });

  final bool editing;
  final String listingId;
  final bool isLoading;
  final bool isLoaded;
  final int step;
  final String condition;
  final String categoryId;
  final bool negotiable;
  final String title;
  final String price;
  final String description;
  final String error;
  final bool isSubmitting;
  final String createdId;
  final String savedId;
  final List<ListingFormImage> images;
  final bool imagesChanged;
  final String listingStatus;
  final bool finishedAsDraft;

  ListingFormState copyWith({
    int? step,
    bool? isLoading,
    bool? isLoaded,
    String? condition,
    String? categoryId,
    bool? negotiable,
    String? title,
    String? price,
    String? description,
    String? error,
    bool? isSubmitting,
    String? createdId,
    String? savedId,
    List<ListingFormImage>? images,
    bool? imagesChanged,
    String? listingStatus,
    bool? finishedAsDraft,
  }) => ListingFormState(
    editing: editing,
    listingId: listingId,
    isLoading: isLoading ?? this.isLoading,
    isLoaded: isLoaded ?? this.isLoaded,
    step: step ?? this.step,
    condition: condition ?? this.condition,
    categoryId: categoryId ?? this.categoryId,
    negotiable: negotiable ?? this.negotiable,
    title: title ?? this.title,
    price: price ?? this.price,
    description: description ?? this.description,
    error: error ?? this.error,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    createdId: createdId ?? this.createdId,
    savedId: savedId ?? this.savedId,
    images: images ?? this.images,
    imagesChanged: imagesChanged ?? this.imagesChanged,
    listingStatus: listingStatus ?? this.listingStatus,
    finishedAsDraft: finishedAsDraft ?? this.finishedAsDraft,
  );
}

class ListingFormCubit extends Cubit<ListingFormState> {
  ListingFormCubit({
    required bool editing,
    String listingId = '',
    ListingRepository? repository,
  }) : _repository = repository ?? ListingRepository(),
       super(
         ListingFormState(
           editing: editing,
           listingId: listingId,
           isLoaded: !editing,
         ),
       );

  final ListingRepository _repository;

  Future<void> load() async {
    if (!state.editing || state.listingId.isEmpty) return;
    emit(state.copyWith(isLoading: true, error: ''));
    try {
      final listing = await _repository.getMine(state.listingId);
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isLoaded: true,
          title: listing.title,
          description: listing.description,
          price: listing.rawPrice,
          categoryId: listing.categoryId,
          condition: listing.conditionCode,
          negotiable: listing.isNegotiable,
          listingStatus: listing.status,
          images: listing.images
              .map((url) => ListingFormImage(url: url))
              .toList(),
        ),
      );
    } on DioException catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: _errorMessage(error)));
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(isLoading: false, error: 'Không tải được tin để sửa.'),
        );
      }
    }
  }

  void nextStep() {
    if (state.categoryId.isEmpty) {
      emit(state.copyWith(error: 'Chọn danh mục cho tin đăng.'));
      return;
    }
    if (state.title.trim().length < 5 || state.title.trim().length > 120) {
      emit(state.copyWith(error: 'Tên sản phẩm cần từ 5 đến 120 ký tự.'));
      return;
    }
    emit(state.copyWith(step: 2, error: ''));
  }

  void previousStep() => emit(state.copyWith(step: 1, error: ''));
  void conditionChanged(String value) => emit(state.copyWith(condition: value));
  void categoryChanged(String value) =>
      emit(state.copyWith(categoryId: value, error: ''));
  void negotiableChanged(bool value) => emit(state.copyWith(negotiable: value));
  void titleChanged(String value) =>
      emit(state.copyWith(title: value, error: ''));
  void priceChanged(String value) =>
      emit(state.copyWith(price: value, error: ''));
  void descriptionChanged(String value) =>
      emit(state.copyWith(description: value, error: ''));

  void addImage(Uint8List bytes) {
    if (state.images.length >= 6) {
      emit(state.copyWith(error: 'Mỗi tin được tối đa 6 ảnh.'));
      return;
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      emit(state.copyWith(error: 'Mỗi ảnh phải nhỏ hơn 5 MB.'));
      return;
    }
    final contentType =
        bytes.length >= 3 &&
            bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[2] == 0xff
        ? 'image/jpeg'
        : bytes.length >= 8 &&
              bytes[0] == 137 &&
              bytes[1] == 80 &&
              bytes[2] == 78 &&
              bytes[3] == 71
        ? 'image/png'
        : bytes.length >= 12 &&
              String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
              String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'
        ? 'image/webp'
        : null;
    if (contentType == null) {
      emit(state.copyWith(error: 'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP.'));
      return;
    }
    emit(
      state.copyWith(
        images: [
          ...state.images,
          ListingFormImage(bytes: bytes, contentType: contentType),
        ],
        imagesChanged: true,
        error: '',
      ),
    );
  }

  void removeImage(int index) {
    final images = [...state.images]..removeAt(index);
    emit(state.copyWith(images: images, imagesChanged: true, error: ''));
  }

  void moveImage(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= state.images.length) return;
    final images = [...state.images];
    final image = images.removeAt(index);
    images.insert(target, image);
    emit(state.copyWith(images: images, imagesChanged: true));
  }

  void imageError(String message) => emit(state.copyWith(error: message));

  Future<void> saveDraft() async {
    if (state.isSubmitting ||
        state.finishedAsDraft ||
        !state.isLoaded ||
        (state.editing && state.listingStatus != 'DRAFT') ||
        state.listingStatus == 'AVAILABLE') {
      return;
    }
    final price = state.price.trim();
    if (price.isNotEmpty && !RegExp(r'^[1-9]\d{0,11}$').hasMatch(price)) {
      emit(state.copyWith(error: 'Giá nháp phải là số nguyên VND hợp lệ.'));
      return;
    }
    emit(state.copyWith(isSubmitting: true, error: ''));
    try {
      final id = state.savedId.isNotEmpty
          ? state.savedId
          : (state.editing ? state.listingId : null);
      final draft = await _repository.saveDraft(
        id: id,
        title: state.title.trim(),
        description: state.description.trim(),
        price: price,
        condition: state.condition,
        categoryId: state.categoryId,
        isNegotiable: state.negotiable,
      );
      if (isClosed) return;
      emit(state.copyWith(savedId: draft.id, listingStatus: 'DRAFT'));
      await _saveImages(draft.id);
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, finishedAsDraft: true));
    } on DioException catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isSubmitting: false, error: _errorMessage(error)));
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isSubmitting: false,
            error: 'Không lưu được bản nháp. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  Future<void> _saveImages(String id) async {
    if (!state.imagesChanged) return;
    final desiredExisting = state.images
        .where((image) => image.url != null)
        .map((image) => image.url!)
        .toList();
    await _repository.replaceImages(id, desiredExisting);
    for (var index = 0; index < state.images.length; index++) {
      final image = state.images[index];
      if (image.bytes == null) continue;
      final url = await _repository.uploadImage(
        id,
        image.bytes!,
        image.contentType!,
      );
      if (isClosed) return;
      final images = [...state.images];
      images[index] = ListingFormImage(url: url);
      emit(state.copyWith(images: images));
    }
    if (isClosed) return;
    await _repository.replaceImages(
      id,
      state.images.map((image) => image.url!).toList(),
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting || state.createdId.isNotEmpty || !state.isLoaded) {
      return;
    }
    if (state.categoryId.isEmpty) {
      emit(state.copyWith(error: 'Chọn danh mục cho tin đăng.'));
      return;
    }
    final price = state.price.trim();
    if (!RegExp(r'^[1-9]\d{0,11}$').hasMatch(price)) {
      emit(
        state.copyWith(
          error: 'Nhập giá VND từ 1 đến 999999999999, không có dấu phân cách.',
        ),
      );
      return;
    }
    if (state.description.trim().length < 20 ||
        state.description.trim().length > 5000) {
      emit(state.copyWith(error: 'Mô tả cần từ 20 đến 5000 ký tự.'));
      return;
    }
    emit(state.copyWith(isSubmitting: true, error: ''));
    try {
      final listing = state.listingStatus == 'DRAFT'
          ? await _repository.saveDraft(
              id: state.savedId.isNotEmpty ? state.savedId : state.listingId,
              title: state.title.trim(),
              description: state.description.trim(),
              price: price,
              condition: state.condition,
              categoryId: state.categoryId,
              isNegotiable: state.negotiable,
            )
          : state.editing || state.savedId.isNotEmpty
          ? await _repository.update(
              state.savedId.isNotEmpty ? state.savedId : state.listingId,
              title: state.title.trim(),
              description: state.description.trim(),
              price: price,
              condition: state.condition,
              categoryId: state.categoryId,
              isNegotiable: state.negotiable,
            )
          : await _repository.create(
              title: state.title.trim(),
              description: state.description.trim(),
              price: price,
              condition: state.condition,
              categoryId: state.categoryId,
              isNegotiable: state.negotiable,
            );
      if (isClosed) {
        return;
      }
      emit(state.copyWith(savedId: listing.id, listingStatus: listing.status));
      await _saveImages(listing.id);
      if (isClosed) return;
      if (state.listingStatus == 'DRAFT') {
        await _repository.publishDraft(listing.id);
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          createdId: listing.id,
          listingStatus: 'AVAILABLE',
        ),
      );
    } on DioException catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isSubmitting: false, error: _errorMessage(error)));
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          error: 'Không đăng được tin. Vui lòng thử lại.',
        ),
      );
    }
  }

  String _errorMessage(DioException error) {
    final body = error.response?.data;
    final message = body is Map<String, dynamic> ? body['error'] : null;
    return message is String
        ? message
        : 'Không lưu được tin. Kiểm tra kết nối rồi thử lại.';
  }
}
