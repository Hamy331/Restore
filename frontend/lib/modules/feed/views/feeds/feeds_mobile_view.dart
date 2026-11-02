import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';

import '../post_composer/post_composer_view.dart';
import 'widgets/feeds_compose_prompt.dart';

class FeedsMobileView extends StatelessWidget {
  const FeedsMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void compose({bool openPhotos = false}) =>
        context.push<String>(PostComposerView.location(openPhotos: openPhotos));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGlassBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Text(
                  l10n.feedsTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FeedsComposePrompt(
                  onTap: compose,
                  onPhotoTap: () => compose(openPhotos: true),
                ),
              ),
              Expanded(
                child: FeedbackView(
                  icon: AppIcons.feeds,
                  title: l10n.feedsTitle,
                  message: l10n.feedsComingSoon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
