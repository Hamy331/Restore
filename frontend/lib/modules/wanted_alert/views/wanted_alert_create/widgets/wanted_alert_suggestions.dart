import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';

import '../../../bloc/wanted_alert_create/wanted_alert_create_state.dart';
import '../../../models/wanted_alert_match.dart';
import '../../../widgets/wanted_alert_match_card.dart';
import 'wanted_alert_create_intro.dart';

/// Bước đầu trang tạo: chưa gõ thì giới thiệu cách hoạt động, gõ rồi thì
/// lưới tin đang có gần giống (điểm cao trước). Nút tạo thông báo nằm ở
/// thanh dưới trang.
class WantedAlertSuggestions extends StatelessWidget {
  final WantedAlertCreateState state;

  /// Chiều cao header nổi phía trên, nội dung chừa chỗ bằng đúng ngần này
  final double topInset;
  final ValueChanged<WantedAlertMatch> onOpenListing;
  final ValueChanged<WantedAlertMatch> onFavoriteTap;
  final VoidCallback onRetry;

  const WantedAlertSuggestions({
    super.key,
    required this.state,
    this.topInset = 0,
    required this.onOpenListing,
    required this.onFavoriteTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (state.previewStatus) {
      case WantedAlertPreviewStatus.idle:
        return WantedAlertCreateIntro(topInset: topInset);
      case WantedAlertPreviewStatus.loading:
        return ListView(
          padding: EdgeInsets.only(top: topInset + 12),
          children: const [AppListingGridSkeleton()],
        );
      case WantedAlertPreviewStatus.failure:
        return _below(
          FeedbackView(
            icon: AppIcons.offline,
            title: l10n.wantedAlertSuggestionsErrorTitle,
            message: l10n.wantedAlertSuggestionsErrorBody,
            action: OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ),
        );
      case WantedAlertPreviewStatus.ready:
        break;
    }

    if (state.suggestions.isEmpty) {
      return _below(
        FeedbackView(
          icon: AppIcons.wantedAlert,
          title: l10n.wantedAlertSuggestionsEmptyTitle,
          message: l10n.wantedAlertSuggestionsEmptyBody,
        ),
      );
    }

    final matches = {
      for (final match in state.suggestions) match.listingId: match,
    };
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wantedAlertSuggestionsTitle(state.suggestions.length),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.wantedAlertSuggestionsHint,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: AppListingSliverGrid(
            items: [for (final match in state.suggestions) match.item],
            itemBuilder: (_, item) {
              final match = matches[item.listing.id]!;
              return WantedAlertMatchCard(
                match: match,
                onTap: () => onOpenListing(match),
                onFavoriteTap: () => onFavoriteTap(match),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  /// Nội dung không cuộn (lỗi, trống) đặt dưới phần header nổi
  Widget _below(Widget child) => Padding(
    padding: EdgeInsets.only(top: topInset),
    child: child,
  );
}
