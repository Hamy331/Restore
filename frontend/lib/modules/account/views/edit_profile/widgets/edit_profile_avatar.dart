import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_local_image.dart';
import '../../../../../shared/widgets/loading/app_loading_indicator.dart';

/// Ảnh đại diện lớn (tròn) kèm các nút đổi ảnh, căn chỉnh và xoá ảnh.
/// [bytes] là ảnh vừa cắt (chưa lưu), ưu tiên hơn [url] đang có trên server.
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

  static const double size = 116;

  final String initials;
  final Uint8List? bytes;
  final String? url;

  /// Đang tải ảnh cũ về để căn chỉnh
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback? onAdjust, onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasAvatar = bytes != null || url != null;
    final Widget image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
        : url != null
        ? AppLocalImage(path: url!, cacheWidth: 400)
        : Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          );
    return Column(
      children: [
        GestureDetector(
          key: const ValueKey('edit-profile-avatar'),
          onTap: busy ? null : onPick,
          child: SizedBox(
            width: size + 8,
            height: size + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySoft,
                    border: Border.all(color: AppColors.surface, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A29231B),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: busy
                        ? const Center(child: AppLoadingIndicator())
                        : image,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: const Icon(
                      AppIcons.camera,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _AvatarAction(
              key: const ValueKey('edit-profile-pick'),
              icon: AppIcons.addPhoto,
              label: l.accChangeAvatar,
              onTap: busy ? null : onPick,
            ),
            if (hasAvatar && onAdjust != null)
              _AvatarAction(
                key: const ValueKey('edit-profile-adjust'),
                icon: AppIcons.zoomIn,
                label: l.accAdjustAvatar,
                onTap: busy ? null : onAdjust,
              ),
            if (hasAvatar && onRemove != null)
              _AvatarAction(
                key: const ValueKey('edit-profile-remove'),
                icon: AppIcons.delete,
                label: l.accRemoveAvatar,
                danger: true,
                onTap: busy ? null : onRemove,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l.accAvatarHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AvatarAction extends StatelessWidget {
  const _AvatarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: danger
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
