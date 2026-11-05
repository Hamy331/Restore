import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/media_picker_service.dart';
import '../../../shared/widgets/app_local_image.dart';
import '../bloc/feeds/feeds_cubit.dart';
import '../bloc/feeds/feeds_state.dart';
import '../models/feed_models.dart';
import 'feed_image_viewer.dart';
import 'feed_shared.dart';

Future<void> showFeedComments(
  BuildContext context,
  FeedsCubit cubit,
  FeedPost post,
) {
  cubit.loadComments(post.id);
  cubit.loadMe();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
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
  final focus = FocusNode();
  final expanded = <String>{};
  FeedComment? replying;
  String? image;
  bool sending = false, picking = false;

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    setState(() => picking = true);
    try {
      final images = await MediaPickerService().pickImages(
        source: MediaSource.gallery,
        limit: 1,
      );
      if (mounted && images.isNotEmpty) setState(() => image = images.first);
    } catch (_) {
      if (mounted) {
        feedNotice(context, AppLocalizations.of(context)!.feedPhotoError);
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> send() async {
    if (sending || picking || (text.text.trim().isEmpty && image == null)) {
      return;
    }
    final cubit = context.read<FeedsCubit>();
    final post = cubit.find(widget.postId);
    if (post == null) return;
    setState(() => sending = true);
    final parentId = replying?.parentId ?? replying?.id;
    final success = await cubit.comment(
      post,
      text.text,
      image: image,
      parentId: parentId,
    );
    if (!mounted) return;
    setState(() {
      sending = false;
      if (success) {
        text.clear();
        image = null;
        replying = null;
        if (parentId != null) expanded.add(parentId);
      }
    });
    if (!success) {
      feedNotice(context, AppLocalizations.of(context)!.feedPublishError);
    }
  }

  void reply(FeedComment comment) {
    setState(() => replying = comment);
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<FeedsCubit, FeedsState>(
      builder: (context, state) {
        final cubit = context.read<FeedsCubit>();
        final comments = state.comments[widget.postId] ?? const <FeedComment>[];
        final ids = comments.map((c) => c.id).toSet();
        final roots = comments
            .where((c) => c.parentId == null || !ids.contains(c.parentId))
            .toList();
        final replies = <String, List<FeedComment>>{};
        for (final comment in comments) {
          if (comment.parentId != null) {
            replies.putIfAbsent(comment.parentId!, () => []).add(comment);
          }
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      '${l.feedComments} (${cubit.find(widget.postId)?.commentCount ?? 0})',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (state.isPending('comments:${widget.postId}'))
              const LinearProgressIndicator(),
            Expanded(
              child: CustomScrollView(
                controller: widget.controller,
                slivers: [
                  if (!state.comments.containsKey(widget.postId) &&
                      !state.isPending('comments:${widget.postId}'))
                    SliverToBoxAdapter(
                      child: TextButton(
                        onPressed: () => cubit.loadComments(widget.postId),
                        child: Text(l.retry),
                      ),
                    )
                  else if (comments.isEmpty &&
                      !state.isPending('comments:${widget.postId}'))
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l.feedNoComments)),
                    )
                  else
                    SliverList.builder(
                      itemCount: roots.length,
                      itemBuilder: (_, index) {
                        final root = roots[index];
                        final children =
                            replies[root.id] ?? const <FeedComment>[];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CommentTile(
                              postId: widget.postId,
                              comment: root,
                              onReply: () => reply(root),
                            ),
                            if (children.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    expanded.contains(root.id)
                                        ? expanded.remove(root.id)
                                        : expanded.add(root.id);
                                  }),
                                  child: Text(
                                    expanded.contains(root.id)
                                        ? l.feedHideReplies
                                        : l.feedViewReplies(children.length),
                                  ),
                                ),
                              ),
                            if (expanded.contains(root.id))
                              for (final child in children)
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: _CommentTile(
                                    postId: widget.postId,
                                    comment: child,
                                    onReply: () => reply(child),
                                  ),
                                ),
                          ],
                        );
                      },
                    ),
                  if (state.hasMoreComments(widget.postId))
                    SliverToBoxAdapter(
                      child: TextButton(
                        onPressed: state.isPending('comments:${widget.postId}')
                            ? null
                            : () =>
                                  cubit.loadComments(widget.postId, more: true),
                        child: Text(l.feedMoreComments),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replying != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.feedReplyTo(replying!.author.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l.feedCancelReply,
                            onPressed: sending
                                ? null
                                : () => setState(() => replying = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    if (image != null)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppLocalImage(
                              path: image!,
                              width: 64,
                              height: 64,
                            ),
                          ),
                          IconButton(
                            tooltip: l.feedRemovePhoto,
                            onPressed: sending
                                ? null
                                : () => setState(() => image = null),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FeedAvatar.me(
                            state.me,
                            fallbackName: l.feedYourName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: text,
                            focusNode: focus,
                            enabled: !sending,
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
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l.feedAddPhoto,
                          onPressed: sending || picking ? null : pick,
                          icon: const Icon(Icons.image_outlined),
                          color: AppColors.primaryDark,
                        ),
                        IconButton(
                          tooltip: l.feedSend,
                          onPressed:
                              sending ||
                                  picking ||
                                  (text.text.trim().isEmpty && image == null)
                              ? null
                              : send,
                          icon: sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(AppIcons.send),
                          color: AppColors.primaryDark,
                        ),
                      ],
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
  const _CommentTile({
    required this.postId,
    required this.comment,
    required this.onReply,
  });
  final String postId;
  final FeedComment comment;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);
    final name = comment.author.name.isEmpty
        ? l.feedYourName
        : comment.author.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAvatar(name: name, size: 32, avatarUrl: comment.author.avatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (comment.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      comment.text,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                if (comment.image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => showFeedImage(
                        context,
                        comment.image!,
                        heroTag: 'comment-${comment.id}',
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 180,
                            maxHeight: 180,
                          ),
                          child: AppLocalImage(
                            path: comment.image!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Text(feedTime(l, comment.createdAt), style: small),
                    TextButton(
                      onPressed: onReply,
                      child: Text(
                        l.feedReply,
                        style: small?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: comment.liked ? l.feedUnlike : l.feedLike,
                isSelected: comment.liked,
                onPressed: () => context.read<FeedsCubit>().toggleCommentLike(
                  postId,
                  comment,
                ),
                icon: Icon(
                  comment.liked ? Icons.favorite : Icons.favorite_border,
                  size: 21,
                  color: comment.liked
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
              if (comment.likes > 0) Text('${comment.likes}', style: small),
            ],
          ),
        ],
      ),
    );
  }
}
