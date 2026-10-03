import 'package:flutter_bloc/flutter_bloc.dart';

class EditProfileState {
  const EditProfileState({
    this.name = 'Ngô Tường Phát',
    this.phone = '090 123 4567',
    this.birthday = '12/08/1996',
    this.gender = 'male',
    this.area = 'district1',
    this.saved = false,
  });

  final String name;
  final String phone;
  final String birthday;
  final String gender;
  final String area;
  final bool saved;

  EditProfileState copyWith({
    String? name,
    String? phone,
    String? birthday,
    String? gender,
    String? area,
    bool? saved,
  }) => EditProfileState(
    name: name ?? this.name,
    phone: phone ?? this.phone,
    birthday: birthday ?? this.birthday,
    gender: gender ?? this.gender,
    area: area ?? this.area,
    saved: saved ?? this.saved,
  );
}

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit() : super(const EditProfileState());

  void nameChanged(String value) => emit(state.copyWith(name: value));
  void phoneChanged(String value) => emit(state.copyWith(phone: value));
  void birthdayChanged(String value) => emit(state.copyWith(birthday: value));
  void genderChanged(String value) => emit(state.copyWith(gender: value));
  void areaChanged(String value) => emit(state.copyWith(area: value));
  void submitted() => emit(state.copyWith(saved: true));
}

class SettingsCubit extends Cubit<bool> {
  SettingsCubit() : super(true);

  void notificationsChanged(bool value) => emit(value);
}

class ReviewState {
  const ReviewState({
    this.rating = 5,
    this.comment = '',
    this.submitted = false,
  });

  final int rating;
  final String comment;
  final bool submitted;

  ReviewState copyWith({int? rating, String? comment, bool? submitted}) =>
      ReviewState(
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        submitted: submitted ?? this.submitted,
      );
}

class ReviewCubit extends Cubit<ReviewState> {
  ReviewCubit() : super(const ReviewState());

  void ratingChanged(int value) => emit(state.copyWith(rating: value));
  void commentChanged(String value) => emit(state.copyWith(comment: value));
  void submitted() => emit(state.copyWith(submitted: true));
}

class ReportState {
  const ReportState({
    this.reason = 'misleading',
    this.description = '',
    this.submitted = false,
  });

  final String reason;
  final String description;
  final bool submitted;

  ReportState copyWith({
    String? reason,
    String? description,
    bool? submitted,
  }) => ReportState(
    reason: reason ?? this.reason,
    description: description ?? this.description,
    submitted: submitted ?? this.submitted,
  );
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit() : super(const ReportState());

  void reasonChanged(String value) => emit(state.copyWith(reason: value));
  void descriptionChanged(String value) =>
      emit(state.copyWith(description: value));
  void submitted() => emit(state.copyWith(submitted: true));
}
