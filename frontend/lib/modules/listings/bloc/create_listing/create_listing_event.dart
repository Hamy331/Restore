import 'package:equatable/equatable.dart';

abstract class CreateListingEvent extends Equatable {
  const CreateListingEvent();
  @override
  List<Object> get props => [];
}

class SelectCategoryEvent extends CreateListingEvent {
  final String categoryId;
  final String categoryName;
  const SelectCategoryEvent(this.categoryId, this.categoryName);
  @override
  List<Object> get props => [categoryId, categoryName];
}

class AddImagesEvent extends CreateListingEvent {
  final List<String> newImages;
  const AddImagesEvent(this.newImages);
}

class RemoveImageEvent extends CreateListingEvent {
  final int index;
  const RemoveImageEvent(this.index);
}

class SetCoverImageEvent extends CreateListingEvent {
  final int index;
  const SetCoverImageEvent(this.index);
}

class UpdateTitleEvent extends CreateListingEvent {
  final String title;
  const UpdateTitleEvent(this.title);
}

class UpdateConditionEvent extends CreateListingEvent {
  final String condition;
  const UpdateConditionEvent(this.condition);
}

class ValidateStep1Event extends CreateListingEvent {}
