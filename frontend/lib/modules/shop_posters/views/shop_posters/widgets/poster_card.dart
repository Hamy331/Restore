import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../../models/shop_poster.dart';
import '../../../utils/poster_labels.dart';
import '../../../widgets/poster_image.dart';

/// Một poster: ảnh 2:1, nhãn trạng thái, tên, khung giờ, nơi mở khi bấm,
/// lý do bị từ chối và nút sửa / dừng
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.poster,
    required this.onEdit,
    required this.onStop,
    this.busy = false,
  });

  final ShopPoster poster;
  final VoidCallback onEdit;
  final VoidCallback onStop;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = poster.state;
    final (color, background) = posterStateColors(state);
    final start = poster.startsAt, end = poster.endsAt;
    final listing = poster.listing;
    final faded =
        state == ShopPosterState.ended || state == ShopPosterState.stopped;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Opacity(
            opacity: faded ? 0.55 : 1,
            child: Semantics(
              label: poster.title,
              image: true,
              child: PosterImage(path: poster.imageUrl, radius: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    l.posterState(state),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  poster.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (start != null && end != null) ...[
                  const SizedBox(height: 6),
                  _Line(
                    icon: AppIcons.calendar,
                    text: l.spDates(
                      posterDay(start),
                      posterDay(end),
                      poster.days ?? end.difference(start).inDays,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _Line(
                  icon: listing == null ? AppIcons.store : AppIcons.link,
                  text: listing == null
                      ? l.spOpensShop
                      : l.spOpensListing(listing.title),
                ),
                if (state == ShopPosterState.rejected &&
                    poster.rejectReason != null)
                  Container(
                    key: const ValueKey('poster-reject-reason'),
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      [
                        l.spRejectedReason(
                          l.rejectReason(poster.rejectReason!),
                        ),
                        if (poster.rejectNote?.isNotEmpty ?? false)
                          poster.rejectNote!,
                      ].join('\n'),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (state.editable || state.stoppable)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AppLoadingIndicator(dotSize: 5),
                    )
                  else if (state.stoppable)
                    TextButton(
                      key: ValueKey('poster-stop-${poster.id}'),
                      onPressed: onStop,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(
                        state == ShopPosterState.pending
                            ? l.spCancel
                            : l.spStop,
                      ),
                    ),
                  if (state.editable) ...[
                    const SizedBox(width: 4),
                    FilledButton.tonalIcon(
                      key: ValueKey('poster-edit-${poster.id}'),
                      onPressed: busy ? null : onEdit,
                      icon: const Icon(AppIcons.edit, size: 16),
                      label: Text(
                        state == ShopPosterState.rejected
                            ? l.spResubmit
                            : l.spEdit,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}
