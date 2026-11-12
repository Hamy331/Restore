import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';

/// Chưa theo dõi shop nào: mời sang trang Shop uy tín
class FollowedShopsEmpty extends StatelessWidget {
  const FollowedShopsEmpty({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FeedbackView(
      icon: AppIcons.shop,
      title: l.followShopsEmpty,
      message: l.followShopsEmptyHint,
      action: FilledButton(
        onPressed: onBrowse,
        child: Text(l.followShopsBrowse),
      ),
    );
  }
}
