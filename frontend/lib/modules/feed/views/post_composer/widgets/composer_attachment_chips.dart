import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_glass_chip.dart';

import '../../../models/post_draft.dart';

/// Hàng chip gắn thêm vào bài: tin đăng của mình, chủ đề, gắn thẻ bạn bè
/// (thay cho Nhạc / Album / Tag friend của Zalo, hợp với chợ đồ cũ hơn).
class ComposerAttachmentChips extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onListingTap;
  final VoidCallback onTopicTap;
  final VoidCallback onClearTopic;
  final VoidCallback onMentionTap;

  const ComposerAttachmentChips({
    super.key,
    required this.draft,
    required this.onListingTap,
    required this.onTopicTap,
    required this.onClearTopic,
    required this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topic = draft.topic;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          AppGlassChip(
            icon: AppIcons.listings,
            label: l10n.postComposerAttachListing,
            isSelected: draft.listing != null,
            onTap: onListingTap,
          ),
          const SizedBox(width: 8),
          AppGlassChip(
            icon: AppIcons.topic,
            label: topic == null
                ? l10n.postComposerTopic
                : topic.name.of(context),
            isSelected: topic != null,
            onTap: onTopicTap,
            onClear: topic == null ? null : onClearTopic,
          ),
          const SizedBox(width: 8),
          AppGlassChip(
            icon: AppIcons.tagFriend,
            label: draft.mentions.isEmpty
                ? l10n.postComposerTagFriends
                : l10n.postComposerTaggedCount(draft.mentions.length),
            isSelected: draft.mentions.isNotEmpty,
            onTap: onMentionTap,
          ),
        ],
      ),
    );
  }
}
