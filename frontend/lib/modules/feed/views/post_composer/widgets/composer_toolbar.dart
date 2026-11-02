import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../bloc/post_composer/post_composer_state.dart';

/// Thanh công cụ kính mờ ngay trên bàn phím: biểu cảm bên trái, ảnh,
/// video, liên kết, vị trí bên phải. Mục đang mở có màu ấm.
class ComposerToolbar extends StatelessWidget {
  final PostComposerPanel panel;
  final bool hasLink;
  final bool hasLocation;
  final VoidCallback onEmojiTap;
  final VoidCallback onPhotoTap;
  final VoidCallback onVideoTap;
  final VoidCallback onLinkTap;
  final VoidCallback onLocationTap;

  const ComposerToolbar({
    super.key,
    required this.panel,
    required this.hasLink,
    required this.hasLocation,
    required this.onEmojiTap,
    required this.onPhotoTap,
    required this.onVideoTap,
    required this.onLinkTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppGlass.fillStrong,
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _ToolButton(
                  icon: AppIcons.emoji,
                  tooltip: l10n.postComposerEmoji,
                  active: panel == PostComposerPanel.emoji,
                  onTap: onEmojiTap,
                ),
                const Spacer(),
                _ToolButton(
                  icon: AppIcons.image,
                  tooltip: l10n.postComposerPhoto,
                  active: panel == PostComposerPanel.photos,
                  onTap: onPhotoTap,
                ),
                _ToolButton(
                  icon: AppIcons.video,
                  tooltip: l10n.postComposerVideo,
                  onTap: onVideoTap,
                ),
                _ToolButton(
                  icon: AppIcons.link,
                  tooltip: l10n.postComposerLink,
                  active: hasLink,
                  onTap: onLinkTap,
                ),
                _ToolButton(
                  icon: AppIcons.location,
                  tooltip: l10n.postComposerLocation,
                  active: hasLocation,
                  onTap: onLocationTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: active ? AppColors.primarySoft : Colors.transparent,
        ),
        icon: Icon(
          icon,
          size: 26,
          color: active ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}
