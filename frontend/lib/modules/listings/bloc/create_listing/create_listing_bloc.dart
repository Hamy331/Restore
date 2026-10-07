import 'package:flutter_bloc/flutter_bloc.dart';
import 'create_listing_event.dart';
import 'create_listing_state.dart';

class CreateListingBloc extends Bloc<CreateListingEvent, CreateListingState> {
  CreateListingBloc() : super(const CreateListingState()) {
    on<SelectCategoryEvent>((event, emit) {
      emit(
        state.copyWith(
          categoryId: event.categoryId,
          categoryName: event.categoryName,
        ),
      );
    });

    on<AddImagesEvent>((event, emit) {
      final updatedImages = List<String>.from(state.images)
        ..addAll(event.newImages);
      if (updatedImages.length > 10) {
        updatedImages.removeRange(10, updatedImages.length);
      }
      emit(state.copyWith(images: updatedImages));
    });

    on<RemoveImageEvent>((event, emit) {
      final updatedImages = List<String>.from(state.images)
        ..removeAt(event.index);
      emit(state.copyWith(images: updatedImages));
    });

    on<SetCoverImageEvent>((event, emit) {
      if (event.index == 0) return;
      final updatedImages = List<String>.from(state.images);
      final selectedImage = updatedImages.removeAt(event.index);
      updatedImages.insert(0, selectedImage);
      emit(state.copyWith(images: updatedImages));
    });

    on<UpdateTitleEvent>((event, emit) {
      final isValid = event.title.trim().length >= 5;
      emit(
        state.copyWith(
          title: event.title,
          isTitleValid: isValid,
          showError: false,
        ),
      );
    });

    on<UpdateConditionEvent>((event, emit) {
      emit(state.copyWith(condition: event.condition));
    });

    on<ValidateStep1Event>((event, emit) {
      final isValid = state.title.trim().length >= 5 && state.images.isNotEmpty;
      emit(state.copyWith(showError: !isValid));
    });
  }
}
