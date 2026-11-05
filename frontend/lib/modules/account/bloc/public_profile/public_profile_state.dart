import 'package:equatable/equatable.dart';
import '../../models/profile_models.dart';

class PublicProfileState extends Equatable {
  const PublicProfileState({
    this.profile,
    this.loading = true,
    this.failed = false,
    this.following = false,
    this.actionFailed = false,
  });
  final ProfileData? profile;
  final bool loading, failed;

  /// Đang gửi yêu cầu theo dõi / bỏ theo dõi.
  final bool following;
  final bool actionFailed;

  @override
  List<Object?> get props => [
    profile,
    loading,
    failed,
    following,
    actionFailed,
  ];
}
