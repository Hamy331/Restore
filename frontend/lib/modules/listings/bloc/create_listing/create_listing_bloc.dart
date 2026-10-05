import 'package:flutter_bloc/flutter_bloc.dart';
import 'create_listing_event.dart';
import 'create_listing_state.dart';

class CreateListingBloc extends Bloc<CreateListingEvent, CreateListingState> {
  CreateListingBloc() : super(const CreateListingState()) {
    on<SelectCategoryEvent>(_onSelectCategory);
  }

  void _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<CreateListingState> emit,
  ) {
    emit(
      state.copyWith(
        categoryId: event.categoryId,
        categoryName: event.categoryName,
      ),
    );
  }
}
