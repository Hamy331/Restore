import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

/// Thẻ kính "Bạn đang nghĩ gì?" ở đầu Bảng tin, bấm để mở màn hình viết
/// bài; nút ảnh bên phải mở thẳng phần chọn ảnh.
class FeedsComposePrompt extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onPhotoTap;

  const FeedsComposePrompt({
    super.key,
    required this.onTap,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppGlassContainer(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                child: Icon(
                  AppIcons.user,
                  size: 22,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.feedsComposePrompt,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.postComposerPhoto,
                onPressed: onPhotoTap,
                icon: const Icon(AppIcons.image, color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
