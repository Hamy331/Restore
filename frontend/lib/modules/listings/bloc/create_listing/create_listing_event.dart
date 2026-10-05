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
