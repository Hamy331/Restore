import 'package:equatable/equatable.dart';

class CreateListingState extends Equatable {
  final String categoryId;
  final String categoryName;

  const CreateListingState({this.categoryId = '', this.categoryName = ''});

  CreateListingState copyWith({String? categoryId, String? categoryName}) {
    return CreateListingState(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  List<Object> get props => [categoryId, categoryName];
}
