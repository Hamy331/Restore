import 'package:flutter_bloc/flutter_bloc.dart';

class ListingFormState {
  const ListingFormState({
    required this.editing,
    this.step = 1,
    this.condition = 'used',
    this.contact = 'chat',
    this.negotiable = true,
    this.title = 'Máy ảnh film Canon AE-1 + lens 50mm',
    this.category = 'Điện tử › Máy ảnh',
    this.price = '2.450.000 đ',
    this.description =
        'Canon AE-1 hoạt động tốt, đo sáng chuẩn. Kèm lens FD 50mm f/1.8, dây đeo và bao da.',
    this.location = 'Quận 1, TP. Hồ Chí Minh',
    this.submitted = false,
    this.photoRequestVersion = 0,
  });

  final bool editing;
  final int step;
  final String condition;
  final String contact;
  final bool negotiable;
  final String title;
  final String category;
  final String price;
  final String description;
  final String location;
  final bool submitted;
  final int photoRequestVersion;

  ListingFormState copyWith({
    int? step,
    String? condition,
    String? contact,
    bool? negotiable,
    String? title,
    String? category,
    String? price,
    String? description,
    String? location,
    bool? submitted,
    int? photoRequestVersion,
  }) => ListingFormState(
    editing: editing,
    step: step ?? this.step,
    condition: condition ?? this.condition,
    contact: contact ?? this.contact,
    negotiable: negotiable ?? this.negotiable,
    title: title ?? this.title,
    category: category ?? this.category,
    price: price ?? this.price,
    description: description ?? this.description,
    location: location ?? this.location,
    submitted: submitted ?? this.submitted,
    photoRequestVersion: photoRequestVersion ?? this.photoRequestVersion,
  );
}

class ListingFormCubit extends Cubit<ListingFormState> {
  ListingFormCubit({required bool editing})
    : super(ListingFormState(editing: editing));

  void nextStep() => emit(state.copyWith(step: 2));
  void previousStep() => emit(state.copyWith(step: 1));
  void conditionChanged(String value) => emit(state.copyWith(condition: value));
  void contactChanged(String value) => emit(state.copyWith(contact: value));
  void negotiableChanged(bool value) => emit(state.copyWith(negotiable: value));
  void titleChanged(String value) => emit(state.copyWith(title: value));
  void categoryChanged(String value) => emit(state.copyWith(category: value));
  void priceChanged(String value) => emit(state.copyWith(price: value));
  void descriptionChanged(String value) =>
      emit(state.copyWith(description: value));
  void locationChanged(String value) => emit(state.copyWith(location: value));
  void photosRequested() =>
      emit(state.copyWith(photoRequestVersion: state.photoRequestVersion + 1));
  void submitted() => emit(state.copyWith(submitted: true));
}
