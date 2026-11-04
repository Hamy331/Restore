import 'package:flutter/widgets.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Ai được xem bài viết trên Bảng tin (cột `audience` của bảng Post).
enum PostAudience {
  everyone('PUBLIC'),
  followers('FOLLOWERS'),
  onlyMe('ONLY_ME');

  const PostAudience(this.apiValue);

  final String apiValue;

  static PostAudience fromApi(String? value) {
    for (final audience in values) {
      if (audience.apiValue == value) return audience;
    }
    return everyone;
  }

  IconData get icon => switch (this) {
    everyone => AppIcons.globe,
    followers => AppIcons.audienceFollowers,
    onlyMe => AppIcons.lock,
  };

  String label(AppLocalizations l10n) => switch (this) {
    everyone => l10n.postAudienceEveryone,
    followers => l10n.postAudienceFollowers,
    onlyMe => l10n.postAudienceOnlyMe,
  };

  String description(AppLocalizations l10n) => switch (this) {
    everyone => l10n.postAudienceEveryoneDesc,
    followers => l10n.postAudienceFollowersDesc,
    onlyMe => l10n.postAudienceOnlyMeDesc,
  };
}
