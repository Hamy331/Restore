import 'package:equatable/equatable.dart';
import '../../models/profile_models.dart';

class FollowListState extends Equatable {
  const FollowListState({
    this.users = const [],
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failed = false,
    this.actionFailed = false,
  });
  final List<FollowUser> users;
  final int page;
  final bool hasMore, loading, failed, actionFailed;

  /// [actionFailed] không được giữ qua các lần emit để snackbar chỉ hiện một lần.
  FollowListState copyWith({
    List<FollowUser>? users,
    int? page,
    bool? hasMore,
    bool? loading,
    bool? failed,
    bool actionFailed = false,
  }) => FollowListState(
    users: users ?? this.users,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    actionFailed: actionFailed,
  );

  @override
  List<Object?> get props => [
    users,
    page,
    hasMore,
    loading,
    failed,
    actionFailed,
  ];
}
