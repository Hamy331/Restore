import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_action_buttons.dart';
import '../../../../../shared/widgets/app_local_image.dart';
import '../../../../../shared/widgets/loading/app_loading_indicator.dart';

/// Ảnh đại diện tròn ở giữa, bên dưới là link "Đổi ảnh đại diện"; bấm ảnh
/// hoặc link đều mở các thao tác ảnh. Chưa có ảnh thì hiện hình người xám.
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
        : const Center(
            child: Icon(Icons.person, size: 64, color: Colors.white),
          );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: l.accChangeAvatar,
            child: GestureDetector(
              key: const ValueKey('edit-profile-avatar'),
              onTap: busy ? null : () => _showActions(context),
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD9D9D9),
                ),
                child: ClipOval(
                  child: busy
                      ? const Center(child: AppLoadingIndicator())
                      : image,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppLinkButton(
            key: const ValueKey('edit-profile-upload'),
            icon: Icons.photo_camera_outlined,
            label: Localizations.localeOf(context).languageCode == 'vi'
                ? 'Đổi ảnh đại diện'
                : 'Change profile photo',
            onPressed: busy ? null : () => _showActions(context),
          ),
        ],
      ),
    );
  }
}
