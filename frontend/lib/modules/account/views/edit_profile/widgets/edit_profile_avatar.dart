import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_local_image.dart';
import '../../../../../shared/widgets/loading/app_loading_indicator.dart';

/// Ảnh đại diện tròn trên nền trắng; nút bút mở các thao tác ảnh.
class EditProfileAvatar extends StatelessWidget {
  const EditProfileAvatar({
    super.key,
    required this.initials,
    required this.onPick,
    this.bytes,
    this.url,
    this.busy = false,
    this.onAdjust,
    this.onRemove,
  });

  static const double size = 112;
  final String initials;
  final Uint8List? bytes;
  final String? url;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback? onAdjust, onRemove;

  void _showActions(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget action(
          String key,
          IconData icon,
          String label,
          VoidCallback callback, {
          bool danger = false,
        }) {
          final color = danger ? AppColors.error : AppColors.textPrimary;
          return ListTile(
            key: ValueKey(key),
            leading: Icon(icon, color: color, size: 22),
            title: Text(label, style: TextStyle(fontSize: 15, color: color)),
            onTap: () {
              Navigator.of(sheetContext).pop();
              callback();
            },
          );
        }

        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              action(
                'edit-profile-pick',
                AppIcons.addPhoto,
                l.accChangeAvatar,
                onPick,
              ),
              if ((bytes != null || url != null) && onAdjust != null)
                action(
                  'edit-profile-adjust',
                  AppIcons.zoomIn,
                  l.accAdjustAvatar,
                  onAdjust!,
                ),
              if ((bytes != null || url != null) && onRemove != null)
                action(
                  'edit-profile-remove',
                  AppIcons.delete,
                  l.accRemoveAvatar,
                  onRemove!,
                  danger: true,
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final Widget image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
        : url != null
        ? AppLocalImage(path: url!, cacheWidth: 400)
        : Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: AppColors.actionPrimary,
              ),
            ),
          );
    return Center(
      child: Semantics(
        button: true,
        label: l.accChangeAvatar,
        child: Tooltip(
          message: l.accChangeAvatar,
          child: GestureDetector(
            key: const ValueKey('edit-profile-avatar'),
            onTap: busy ? null : () => _showActions(context),
            child: SizedBox.square(
              dimension: size + 12,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF5F7FA),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ClipOval(
                      child: busy
                          ? const Center(child: AppLoadingIndicator())
                          : image,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B7280),
                        border: Border.all(color: AppColors.surface, width: 3),
                      ),
                      child: const Icon(
                        AppIcons.edit,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
