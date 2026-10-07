import 'package:equatable/equatable.dart';

class CreateListingState extends Equatable {
  final String categoryId;
  final String categoryName;
  final List<String> images; // Danh sách đường dẫn ảnh
  final String title;
  final String condition; // 'NEW' hoặc 'USED'
  final bool isTitleValid;
  final bool showError;

  const CreateListingState({
    this.categoryId = '',
    this.categoryName = '',
    this.images = const [],
    this.title = '',
    this.condition = 'NEW', // Mặc định là Mới
    this.isTitleValid = false,
    this.showError = false,
  });

  CreateListingState copyWith({
    String? categoryId,
    String? categoryName,
    List<String>? images,
    String? title,
    String? condition,
    bool? isTitleValid,
    bool? showError,
  }) {
    return CreateListingState(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      images: images ?? this.images,
      title: title ?? this.title,
      condition: condition ?? this.condition,
      isTitleValid: isTitleValid ?? this.isTitleValid,
      showError: showError ?? this.showError,
    );
  }

  @override
  List<Object> get props => [
    categoryId,
    categoryName,
    images,
    title,
    condition,
    isTitleValid,
    showError,
  ];
}
