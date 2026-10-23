import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../../bloc/wanted_alert_create/wanted_alert_create_state.dart';
import '../../../models/wanted_alert_match.dart';
import '../../../widgets/wanted_alert_match_card.dart';

/// Hàng ngang các tin đang khớp nội dung đang soạn, cập nhật theo từ khoá,
/// tiêu chí và mức độ giống để người dùng thấy thông báo sẽ "bắt" tin nào
class WantedAlertPreviewStrip extends StatelessWidget {
  final WantedAlertPreviewStatus status;
  final List<WantedAlertMatch> matches;
  final ValueChanged<WantedAlertMatch> onOpenListing;
  final ValueChanged<WantedAlertMatch> onFavoriteTap;
  final VoidCallback onRetry;

  const WantedAlertPreviewStrip({
    super.key,
    required this.status,
    required this.matches,
    required this.onOpenListing,
    required this.onFavoriteTap,
    required this.onRetry,
  });

  static const double _cardWidth = 150;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = AppListingCard.heightFor(_cardWidth);

    switch (status) {
      case WantedAlertPreviewStatus.idle:
        return _Message(text: l10n.wantedAlertPreviewNeedKeywords);
      case WantedAlertPreviewStatus.loading:
        return SizedBox(
          height: 120,
          child: const Center(child: AppLoadingIndicator()),
        );
      case WantedAlertPreviewStatus.failure:
        return _Message(
          text: l10n.wantedAlertSuggestionsErrorTitle,
          action: TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        );
      case WantedAlertPreviewStatus.ready:
        break;
    }

    if (matches.isEmpty) return _Message(text: l10n.wantedAlertPreviewEmpty);

    // Cuộn ngang tràn ra hai mép trang cho tự nhiên
    return SizedBox(
      height: height,
      child: OverflowBox(
        maxWidth: MediaQuery.sizeOf(context).width,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: matches.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final match = matches[index];
            return SizedBox(
              width: _cardWidth,
              child: WantedAlertMatchCard(
                match: match,
                onTap: () => onOpenListing(match),
                onFavoriteTap: () => onFavoriteTap(match),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
