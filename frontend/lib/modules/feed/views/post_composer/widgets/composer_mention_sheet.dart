import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

import '../../../models/post_mention.dart';

/// Sheet chọn nhiều người để gắn thẻ; trả về danh sách đã chọn, null khi
/// đóng sheet mà không bấm Xong.
Future<List<PostMention>?> showComposerMentionSheet(
  BuildContext context, {
  required List<PostMention> options,
  required List<PostMention> selected,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<List<PostMention>>(
    context,
    title: l10n.postComposerTagFriends,
    subtitle: l10n.postComposerTagFriendsHint,
    icon: AppIcons.tagFriend,
    builder: (_) => _MentionList(options: options, initial: selected),
  );
}

class _MentionList extends StatefulWidget {
  final List<PostMention> options;
  final List<PostMention> initial;

  const _MentionList({required this.options, required this.initial});

  @override
  State<_MentionList> createState() => _MentionListState();
}

class _MentionListState extends State<_MentionList> {
  late final List<PostMention> _selected = [...widget.initial];

  void _toggle(PostMention mention) => setState(() {
    if (!_selected.remove(mention)) _selected.add(mention);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final mention in widget.options)
                CheckboxListTile(
                  value: _selected.contains(mention),
                  onChanged: (_) => _toggle(mention),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primaryDark,
                    child: Text(mention.fullName.characters.first),
                  ),
                  title: Text(
                    mention.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppPrimaryActionButton(
            label: l10n.postComposerDone,
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ),
      ],
    );
  }
}
