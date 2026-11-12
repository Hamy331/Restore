import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'follow_list_mobile_view.dart';
import '../../models/profile_models.dart';
import '../../repositories/profile_repository.dart';

class FollowListView extends StatelessWidget {
  const FollowListView({
    super.key,
    required this.userId,
    this.initial = FollowListKind.followers,
    this.repository,
    this.showShops = false,
    this.openShops = false,
  });
  final String userId;
  final FollowListKind initial;
  final ProfileRepository? repository;

  /// Xem [FollowListMobileView.showShops]
  final bool showShops, openShops;
  @override
  Widget build(BuildContext context) => TResponsiveLayout(
    mobile: FollowListMobileView(
      userId: userId,
      initial: initial,
      repository: repository,
      showShops: showShops,
      openShops: openShops,
    ),
  );
}
