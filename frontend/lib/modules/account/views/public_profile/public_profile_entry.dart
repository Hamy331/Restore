import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/routes/profile_path.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../models/profile_models.dart';
import '../../repositories/profile_repository.dart';
import '../reviews/seller_reviews_view.dart';
import 'public_profile_view.dart';

/// Cửa vào trang hồ sơ công khai, dùng chung cho `/u/@tên` và `/users/<id>`.
///
/// Tải hồ sơ theo [param] (tên có `@` hoặc id) để biết id thật, rồi:
/// - vào bằng `/users/<id>` mà hồ sơ có tên người dùng: đổi sang `/u/@tên`;
/// - mở trang hồ sơ với id thật (bài viết, theo dõi... cần id).
/// [openReviews] (liên kết `?tab=reviews`) mở thẳng trang đánh giá.
class PublicProfileEntry extends StatefulWidget {
  const PublicProfileEntry({
    super.key,
    required this.param,
    this.openReviews = false,
    this.repository,
  });

  final String param;
  final bool openReviews;
  final ProfileRepository? repository;

  @override
  State<PublicProfileEntry> createState() => _PublicProfileEntryState();
}

class _PublicProfileEntryState extends State<PublicProfileEntry> {
  ProfileData? _profile;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final profile = await (widget.repository ?? ApiProfileRepository())
          .getUser(widget.param);
      if (!mounted) return;
      final canonical = profilePath(
        id: profile.id,
        username: profile.username,
      );
      if (widget.openReviews) {
        context.replace(SellerReviewsView.location(profile.id));
      } else if (usernameFromHandle(widget.param) == null &&
          canonical != '/users/${profile.id}') {
        context.replace(canonical);
      } else {
        setState(() => _profile = profile);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile != null) {
      return PublicProfileView(
        userId: profile.id,
        repository: widget.repository,
      );
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Center(
        child: _failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.accUserNotFound),
                  TextButton(onPressed: _load, child: Text(l.retry)),
                ],
              )
            : const AppLoadingIndicator(),
      ),
    );
  }
}
