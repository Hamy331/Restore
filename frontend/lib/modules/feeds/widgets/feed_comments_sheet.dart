import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/feeds/feeds_cubit.dart';
import '../bloc/feeds/feeds_state.dart';
import '../models/feed_models.dart';
import 'feed_shared.dart';

Future<void> showFeedComments(
  BuildContext context,
  FeedsCubit cubit,
  FeedPost post,
) {
  cubit.loadComments(post.id);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        minChildSize: .4,
        maxChildSize: .95,
        builder: (_, controller) => BlocProvider.value(
          value: cubit,
          child: _Comments(postId: post.id, controller: controller),
        ),
      ),
    ),
  );
}

class _Comments extends StatefulWidget {
  const _Comments({required this.postId, required this.controller});
  final String postId;
  final ScrollController controller;
  @override
  State<_Comments> createState() => _CommentsState();
}

class _CommentsState extends State<_Comments> {
  final text = TextEditingController();
  bool sending = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (sending) return;
    setState(() => sending = true);
    final post = context.read<FeedsCubit>().find(widget.postId);
    if (post == null ||
        !await context.read<FeedsCubit>().comment(post, text.text) ||
        !mounted) {
      if (mounted) setState(() => sending = false);
      return;
    }
    text.clear();
    sending = false;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = widget.controller;
      if (!mounted || !controller.hasClients) return;
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<FeedsCubit, FeedsState>(
      builder: (context, state) {
        final cubit = context.read<FeedsCubit>();
        final comments = state.comments[widget.postId] ?? const <FeedComment>[];
        return Column(
          children: [
            if (state.isPending('comments:${widget.postId}'))
              const LinearProgressIndicator(),
            // Chưa tải được bình luận lần nào và không còn đang tải: cho thử lại.
            if (!state.comments.containsKey(widget.postId) &&
                !state.isPending('comments:${widget.postId}'))
              TextButton(
                onPressed: () => cubit.loadComments(widget.postId),
                child: Text(l.retry),
              ),

            Expanded(
              child: CustomScrollView(
                controller: widget.controller,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Text(
                        comments.isEmpty
                            ? l.feedComments
                            : '${l.feedComments} (${cubit.find(widget.postId)?.commentCount ?? 0})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  if (comments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l.feedNoComments)),
                    )
                  else
                    SliverList.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, index) => _CommentTile(
                        postId: widget.postId,
                        comment: comments[index],
                      ),
                    ),
                ],
              ),
            ),
            if (state.hasMoreComments(widget.postId))
              TextButton(
                onPressed: () => cubit.loadComments(widget.postId, more: true),
                child: const Icon(Icons.expand_more),
              ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    FeedAvatar.me(state.me, fallbackName: l.feedYourName),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: text,
                        maxLength: 2000,
                        maxLines: 3,
                        minLines: 1,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: l.feedCommentHint,
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.feedSend,
                      color: AppColors.primaryDark,
                      icon: const Icon(AppIcons.send),
                      onPressed: sending || text.text.trim().isEmpty
                          ? null
                          : send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.postId, required this.comment});
  final String postId;
  final FeedComment comment;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = comment.author.name.isEmpty
        ? l.feedYourName
        : comment.author.name;
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAvatar(name: name, size: 32, avatarUrl: comment.author.avatarUrl),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(comment.text),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(feedTime(l, comment.createdAt), style: small),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: comment.liked ? l.feedUnlike : l.feedLike,
                      child: InkWell(
                        onTap: () => context
                            .read<FeedsCubit>()
                            .toggleCommentLike(postId, comment),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                l.feedLike,
                                style: small?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: comment.liked
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (comment.likes > 0)
                      Semantics(
                        label: l.feedLikes(comment.likes),
                        child: Text('${comment.likes}', style: small),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
