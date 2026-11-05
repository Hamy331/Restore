import 'package:equatable/equatable.dart';
import '../../models/profile_models.dart';

enum ProfileSaveResult { saved, usernameTaken, invalidUsername, failed }

class UserProfileState extends Equatable {
  const UserProfileState({
    this.profile,
    this.loading = true,
    this.saving = false,
    this.failed = false,
  });
  final ProfileData? profile;
  final bool loading;
  final bool saving;
  final bool failed;

  @override
  List<Object?> get props => [profile, loading, saving, failed];
}
