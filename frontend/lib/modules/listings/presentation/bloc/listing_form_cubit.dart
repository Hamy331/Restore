import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/listing_repository.dart';

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
      final listing = state.editing
          ? await _repository.update(
              state.listingId,
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
      emit(state.copyWith(isSubmitting: false, createdId: listing.id));
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
