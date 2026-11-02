import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_glass_chip.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../models/post_draft.dart';

/// Những gì đã gắn vào bài, hiện dưới nội dung: thẻ tin đăng, liên kết,
/// vị trí và người được gắn thẻ. Mỗi mục có nút bỏ.
class ComposerAttachedInfo extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onRemoveListing;
  final VoidCallback onRemoveLink;
  final VoidCallback onRemoveLocation;
  final VoidCallback onEditMentions;

  const ComposerAttachedInfo({
    super.key,
    required this.draft,
    required this.onRemoveListing,
    required this.onRemoveLink,
    required this.onRemoveLocation,
    required this.onEditMentions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listing = draft.listing;
    final link = draft.linkUrl;
    final location = draft.location;
    final mentions = draft.mentions;
    if (listing == null &&
        link == null &&
        location == null &&
        mentions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (listing != null)
            _AttachmentCard(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 52,
                  child: listing.imageUrl == null
                      ? const ColoredBox(
                          color: AppColors.primarySoft,
                          child: Icon(AppIcons.listings),
                        )
                      : AppLocalImage(path: listing.imageUrl!, cacheWidth: 160),
                ),
              ),
              title: listing.title,
              subtitle: listing.price == null
                  ? l10n.postComposerListingTag
                  : CurrencyFormatter.formatVnd(listing.price!),
              removeTooltip: l10n.postComposerRemoveAttachment,
              onRemove: onRemoveListing,
            ),
          if (link != null)
            _AttachmentCard(
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(AppIcons.link, color: AppColors.info),
              ),
              title: Uri.tryParse(link)?.host.isNotEmpty == true
                  ? Uri.parse(link).host
                  : link,
              subtitle: link,
              removeTooltip: l10n.postComposerRemoveAttachment,
              onRemove: onRemoveLink,
            ),
          if (location != null || mentions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (location != null)
                  AppGlassChip(
                    icon: AppIcons.location,
                    label: location.label,
                    isSelected: true,
                    maxLabelWidth: 280,
                    onClear: onRemoveLocation,
                  ),
                if (mentions.isNotEmpty)
                  AppGlassChip(
                    icon: AppIcons.tagFriend,
                    label: mentions.length == 1
                        ? l10n.postComposerWithOne(mentions.first.fullName)
                        : l10n.postComposerWithMany(
                            mentions.first.fullName,
                            mentions.length - 1,
                          ),
                    isSelected: true,
                    maxLabelWidth: 280,
                    onTap: onEditMentions,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String removeTooltip;
  final VoidCallback onRemove;

  const _AttachmentCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.removeTooltip,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: removeTooltip,
            onPressed: onRemove,
            icon: const Icon(AppIcons.close, size: 20),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
