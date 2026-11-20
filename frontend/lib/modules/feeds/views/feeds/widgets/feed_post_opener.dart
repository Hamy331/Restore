import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../bloc/feeds/feeds_cubit.dart';
import '../../../widgets/feed_comments_sheet.dart';
import '../../../widgets/feed_shared.dart';

/// Mở bình luận của bài [postId] khi vào trang (bấm thông báo thích / bình luận / trả lời).
/// Đổi [postId] (bấm thông báo khác khi đang ở bảng tin) thì mở bài mới.
class FeedPostOpener extends StatefulWidget {
  const FeedPostOpener({super.key, required this.postId, required this.child});

  final String? postId;
  final Widget child;

  @override
  State<FeedPostOpener> createState() => _FeedPostOpenerState();
}

class _FeedPostOpenerState extends State<FeedPostOpener> {
  String? _opened;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(FeedPostOpener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) _schedule();
  }

  void _schedule() {
    final id = widget.postId;
    if (id == null || id.isEmpty || id == _opened) return;
    _opened = id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(id));
  }

  Future<void> _open(String id) async {
    if (!mounted) return;
    final cubit = context.read<FeedsCubit>();
    final l10n = AppLocalizations.of(context)!;
    try {
      final post = await cubit.repository.post(id);
      if (!mounted) return;
      await showFeedComments(context, cubit, post);
    } catch (_) {
      if (mounted) feedNotice(context, l10n.feedPostUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
