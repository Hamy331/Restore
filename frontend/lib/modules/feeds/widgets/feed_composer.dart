import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/media_picker_service.dart';
import '../../../shared/widgets/app_local_image.dart';
import '../bloc/feeds/feeds_cubit.dart';
import 'feed_shared.dart';

Future<void> showFeedComposer(BuildContext context, FeedsCubit cubit) =>
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _Composer(cubit: cubit),
      ),
    );

class _Composer extends StatefulWidget {
  const _Composer({required this.cubit});
  final FeedsCubit cubit;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final text = TextEditingController();
  String? image;
  bool picking = false, submitted = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> pick(MediaSource source) async {
    setState(() => picking = true);
    try {
      final images = await MediaPickerService().pickImages(
        source: source,
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

  Future<void> submit() async {
    final l = AppLocalizations.of(context)!;
    setState(() => submitted = true);
    final success = await widget.cubit.publish(text.text, image);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => submitted = false);
      feedNotice(
        context,
        text.text.trim().isEmpty && image == null
            ? l.feedRequired
            : l.feedPublishError,
      );
    }
  }

  bool get dirty => text.text.trim().isNotEmpty || image != null;

  Future<void> confirmDiscard() async {
    final l = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.feedDiscardTitle),
        content: Text(l.feedDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.feedKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.feedDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final small = Theme.of(context).textTheme.bodySmall;
    final canPost =
        !submitted &&
        !picking &&
        (text.text.trim().isNotEmpty || image != null);
    // Navigator.pop khi đăng thành công không đi qua PopScope; nút đóng và
    // nút back của hệ thống thì có, nên hỏi trước khi bỏ nội dung đã nhập.
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !submitted) confirmDiscard();
      },
      child: _buildPage(context, l, small, canPost),
    );
  }

  Widget _buildPage(
    BuildContext context,
    AppLocalizations l,
    TextStyle? small,
    bool canPost,
  ) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l.cancel,
                    icon: const Icon(AppIcons.close, size: 22),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l.feedNewPost,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: canPost ? submit : null,
                    child: Text(
                      l.feedPost,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  TextField(
                    controller: text,
                    autofocus: true,
                    maxLines: null,
                    minLines: 6,
                    maxLength: 2000,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: l.feedTextHint,
                      counterText: '',
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  if (image != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppLocalImage(
                            path: image!,
                            width: double.infinity,
                            height: 220,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filledTonal(
                            tooltip: l.feedRemovePhoto,
                            icon: const Icon(AppIcons.close, size: 18),
                            onPressed: () => setState(() => image = null),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l.feedAddPhoto,
                    color: AppColors.primaryDark,
                    icon: const Icon(AppIcons.image),
                    onPressed: picking ? null : () => pick(MediaSource.gallery),
                  ),
                  IconButton(
                    tooltip: l.feedTakePhoto,
                    icon: const Icon(AppIcons.camera),
                    onPressed: picking ? null : () => pick(MediaSource.camera),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        l.feedCharCount(text.text.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: small,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
