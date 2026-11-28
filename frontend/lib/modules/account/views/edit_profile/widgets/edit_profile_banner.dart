import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../shared/widgets/app_local_image.dart';
import '../../../../../shared/widgets/loading/app_loading_indicator.dart';
import '../../../widgets/profile_plain_cover.dart';

/// Ảnh bìa hồ sơ ở đầu trang sửa hồ sơ, ảnh đại diện [avatar] đè lên mép dưới.
/// Cửa hàng ([editable]) bấm vào để đổi bìa; người dùng thường chỉ thấy bìa
/// mặc định có khoá, bấm vào sẽ được nhắc lên Cửa hàng.
class EditProfileBanner extends StatelessWidget {
  const EditProfileBanner({
    super.key,
    required this.avatar,
    required this.editable,
    required this.onTap,
    required this.changeLabel,
    required this.lockedLabel,
    this.url,
    this.bytes,
    this.busy = false,
  });

  /// Nửa chiều cao ảnh đại diện nhô xuống dưới bìa
  static const double avatarOverlap = 56;

  final Widget avatar;
  final bool editable, busy;
  final String? url;
  final Uint8List? bytes;
  final VoidCallback? onTap;
  final String changeLabel, lockedLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.maxWidth / 3;
      final Widget cover = bytes != null
          ? Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
          : editable && url != null
          ? AppLocalImage(path: url!, cacheWidth: 1000)
          : const ProfilePlainCover();
      return Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: Semantics(
              button: true,
              label: editable ? changeLabel : lockedLabel,
              child: GestureDetector(
                key: const ValueKey('edit-profile-banner'),
                onTap: busy ? null : onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      cover,
                      if (busy)
                        const ColoredBox(
                          color: Color(0x55000000),
                          child: Center(child: AppLoadingIndicator()),
                        ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _Pill(
                          icon: editable ? AppIcons.camera : AppIcons.lock,
                          label: editable ? changeLabel : lockedLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: height - avatarOverlap),
            child: avatar,
          ),
        ],
      );
    },
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
