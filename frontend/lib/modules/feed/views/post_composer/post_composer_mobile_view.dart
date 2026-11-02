import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/enums/post_audience.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';

import '../../bloc/post_composer/post_composer_cubit.dart';
import '../../bloc/post_composer/post_composer_state.dart';
import '../../models/post_listing_ref.dart';
import '../../models/post_topic.dart';
import 'widgets/composer_attached_info.dart';
import 'widgets/composer_attachment_chips.dart';
import 'widgets/composer_emoji_panel.dart';
import 'widgets/composer_link_sheet.dart';
import 'widgets/composer_mention_sheet.dart';
import 'widgets/composer_photo_panel.dart';
import 'widgets/composer_selected_photos.dart';
import 'widgets/composer_style_row.dart';
import 'widgets/composer_text_area.dart';
import 'widgets/composer_toolbar.dart';
import 'widgets/composer_top_bar.dart';

class PostComposerMobileView extends StatefulWidget {
  const PostComposerMobileView({super.key, this.mediaPicker});

  /// Truyền vào khi test; mặc định dùng image_picker
  final MediaPickerService? mediaPicker;

  @override
  State<PostComposerMobileView> createState() => _PostComposerMobileViewState();
}

class _PostComposerMobileViewState extends State<PostComposerMobileView> {
  /// Chiều cao khung ảnh/biểu cảm, gần bằng bàn phím
  static const double _panelHeight = 300;

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  late final _mediaPicker = widget.mediaPicker ?? MediaPickerService();

  PostComposerCubit get _cubit => context.read<PostComposerCubit>();
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    // Gõ chữ thì bàn phím thế chỗ khung ảnh/biểu cảm
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) _cubit.closePanel();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Các mục cần dữ liệu từ API; chưa tải xong thì báo và tải lại
  bool _ensureOptions() {
    final status = _cubit.state.status;
    if (status == PostComposerStatus.ready) return true;
    if (status == PostComposerStatus.failure) {
      TSnackBarHelper.showError(context, message: _l10n.postComposerLoadError);
      _cubit.start();
    }
    return false;
  }

  Future<void> _close() async {
    if (!_cubit.state.draft.hasContent) {
      context.pop();
      return;
    }
    final discard = await showAppOptionSheet<bool>(
      context,
      title: _l10n.postComposerDiscardTitle,
      subtitle: _l10n.postComposerDiscardMessage,
      options: [
        AppSheetOption(false, _l10n.postComposerKeepEditing),
        AppSheetOption(true, _l10n.postComposerDiscard),
      ],
    );
    if (discard == true && mounted) context.pop();
  }

  Future<void> _pickAudience() async {
    final audience = await showAppOptionSheet<PostAudience>(
      context,
      title: _l10n.postAudienceTitle,
      selected: _cubit.state.draft.audience,
      options: [
        for (final audience in PostAudience.values)
          AppSheetOption(
            audience,
            audience.label(_l10n),
            subtitle: audience.description(_l10n),
            icon: audience.icon,
          ),
      ],
    );
    if (audience != null) _cubit.setAudience(audience);
  }

  void _openPanel(PostComposerPanel panel) {
    _focusNode.unfocus();
    _cubit.openPanel(panel);
  }

  void _togglePhoto(String path) {
    if (!_cubit.togglePhoto(path)) _warnPhotoLimit();
  }

  void _warnPhotoLimit() => TSnackBarHelper.showWarning(
    context,
    message: _l10n.postComposerPhotoLimit(_cubit.state.options.maxPhotos),
  );

  Future<void> _pickPhotos(MediaSource source) async {
    final remaining = _cubit.state.remainingPhotos;
    if (remaining <= 0) {
      _warnPhotoLimit();
      return;
    }
    try {
      final paths = await _mediaPicker.pickImages(
        source: source,
        limit: remaining,
      );
      if (paths.isNotEmpty) _cubit.addPhotos(paths);
    } on PlatformException {
      if (!mounted) return;
      TSnackBarHelper.showError(
        context,
        message: _l10n.postComposerPhotoPermission,
      );
    }
  }

  void _insertEmoji(String emoji) {
    final value = _textController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final text = value.text.replaceRange(selection.start, selection.end, emoji);
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
    _cubit.contentChanged(text);
  }

  Future<void> _pickListing() async {
    if (!_ensureOptions()) return;
    final listings = _cubit.state.options.myListings;
    if (listings.isEmpty) {
      TSnackBarHelper.showInfo(context, message: _l10n.postComposerNoListings);
      return;
    }
    final listing = await showAppOptionSheet<PostListingRef>(
      context,
      title: _l10n.postComposerAttachListing,
      subtitle: _l10n.postComposerAttachListingHint,
      icon: AppIcons.listings,
      selected: _cubit.state.draft.listing,
      options: [
        for (final listing in listings)
          AppSheetOption(
            listing,
            listing.title,
            subtitle: listing.price == null
                ? null
                : CurrencyFormatter.formatVnd(listing.price!),
          ),
      ],
    );
    if (listing != null) _cubit.setListing(listing);
  }

  Future<void> _pickTopic() async {
    if (!_ensureOptions()) return;
    final topic = await showAppOptionSheet<PostTopic>(
      context,
      title: _l10n.postComposerTopic,
      subtitle: _l10n.postComposerTopicHint,
      icon: AppIcons.topic,
      selected: _cubit.state.draft.topic,
      options: [
        for (final topic in _cubit.state.options.topics)
          AppSheetOption(topic, topic.name.of(context)),
      ],
    );
    if (topic != null) _cubit.setTopic(topic);
  }

  Future<void> _pickMentions() async {
    if (!_ensureOptions()) return;
    final mentions = await showComposerMentionSheet(
      context,
      options: _cubit.state.options.mentionable,
      selected: _cubit.state.draft.mentions,
    );
    if (mentions == null) return;
    for (final mention in {..._cubit.state.draft.mentions, ...mentions}) {
      final wanted = mentions.contains(mention);
      if (wanted != _cubit.state.draft.mentions.contains(mention)) {
        _cubit.toggleMention(mention);
      }
    }
  }

  Future<void> _editLink() async {
    final link = await showComposerLinkSheet(
      context,
      initial: _cubit.state.draft.linkUrl,
    );
    if (link != null) _cubit.setLink(link);
  }

  Future<void> _pickLocation() async {
    final result = await context.push<AreaPickResult>(
      AreaSearchView.location(),
    );
    if (!mounted || result == null) return;
    if (result.area case final area?) {
      _cubit.setLocation(area);
    } else {
      // Lấy vị trí GPS cho bài viết sẽ làm cùng Bảng tin
      TSnackBarHelper.showInfo(context, message: _l10n.featureComingSoon);
    }
  }

  Future<void> _submit() async {
    _focusNode.unfocus();
    final id = await _cubit.submit();
    if (!mounted) return;
    if (id == null) {
      TSnackBarHelper.showError(context, message: _l10n.postComposerError);
      return;
    }
    TSnackBarHelper.showSuccess(context, message: _l10n.postComposerPosted);
    context.pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return BlocBuilder<PostComposerCubit, PostComposerState>(
      builder: (context, state) {
        final draft = state.draft;
        final panelOpen = state.panel != PostComposerPanel.none;
        return PopScope(
          canPop: !draft.hasContent,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close();
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AppGlassBackground(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    ComposerTopBar(
                      audience: draft.audience,
                      canSubmit: state.canSubmit,
                      isSubmitting: state.isSubmitting,
                      onClose: _close,
                      onAudienceTap: _pickAudience,
                      onSubmit: _submit,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _focusNode.requestFocus,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 16),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            ComposerTextArea(
                              controller: _textController,
                              focusNode: _focusNode,
                              background: draft.background,
                              onChanged: _cubit.contentChanged,
                            ),
                            ComposerSelectedPhotos(
                              photos: draft.photos,
                              onRemove: _cubit.removePhoto,
                            ),
                            ComposerAttachedInfo(
                              draft: draft,
                              onRemoveListing: () => _cubit.setListing(null),
                              onRemoveLink: () => _cubit.setLink(null),
                              onRemoveLocation: () => _cubit.setLocation(null),
                              onEditMentions: _pickMentions,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ComposerStyleRow(
                      backgrounds: state.options.backgrounds,
                      selected: draft.background,
                      expanded: state.showBackgrounds,
                      enabled:
                          state.canUseBackground &&
                          state.options.backgrounds.isNotEmpty,
                      onToggle: _cubit.toggleBackgrounds,
                      onSelect: _cubit.selectBackground,
                    ),
                    ComposerAttachmentChips(
                      draft: draft,
                      onListingTap: _pickListing,
                      onTopicTap: _pickTopic,
                      onClearTopic: () => _cubit.setTopic(null),
                      onMentionTap: _pickMentions,
                    ),
                    ComposerToolbar(
                      panel: state.panel,
                      hasLink: draft.linkUrl != null,
                      hasLocation: draft.location != null,
                      onEmojiTap: () => _openPanel(PostComposerPanel.emoji),
                      onPhotoTap: () => _openPanel(PostComposerPanel.photos),
                      onVideoTap: () => TSnackBarHelper.showInfo(
                        context,
                        message: _l10n.featureComingSoon,
                      ),
                      onLinkTap: _editLink,
                      onLocationTap: _pickLocation,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        height: panelOpen
                            ? _panelHeight + bottomInset
                            : (keyboardOpen ? 0 : bottomInset),
                        child: switch (state.panel) {
                          PostComposerPanel.photos => ComposerPhotoPanel(
                            recentPhotos: state.recentPhotos,
                            selected: draft.photos,
                            onCameraTap: () => _pickPhotos(MediaSource.camera),
                            onGalleryTap: () =>
                                _pickPhotos(MediaSource.gallery),
                            onPhotoTap: _togglePhoto,
                          ),
                          PostComposerPanel.emoji => ComposerEmojiPanel(
                            onSelected: _insertEmoji,
                          ),
                          PostComposerPanel.none => null,
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
