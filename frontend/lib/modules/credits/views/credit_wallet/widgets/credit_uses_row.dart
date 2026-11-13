import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/shared/widgets/app_image_icon.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/plans/views/plans/plans_view.dart';

/// "Dùng xu để": đăng thêm tin, đẩy tin, nâng gói.
/// Trừ xu cho các việc này làm ở bước định mức sau, nên tạm báo sắp có.
class CreditUsesRow extends StatelessWidget {
  const CreditUsesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void soon() =>
        TSnackBarHelper.showInfo(context, message: l10n.featureComingSoon);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.creditUsesTitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Use(
              icon: AppIcons.post,
              image: AppImages.uiIcons.post,
              label: l10n.creditUsePostMore,
              onTap: soon,
            ),
            const SizedBox(width: 8),
            _Use(
              icon: AppIcons.boost,
              image: AppImages.uiIcons.boost,
              label: l10n.creditUseBoost,
              onTap: soon,
            ),
            const SizedBox(width: 8),
            _Use(
              icon: AppIcons.pro,
              image: AppImages.uiIcons.crown,
              label: l10n.creditUseUpgrade,
              onTap: () => context.push(PlansView.path),
            ),
          ],
        ),
      ],
    );
  }
}

class _Use extends StatelessWidget {
  final IconData icon;
  final String image;
  final String label;
  final VoidCallback onTap;

  const _Use({
    required this.icon,
    required this.image,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppGlassContainer(
        borderRadius: BorderRadius.circular(18),
        showShadow: false,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                AppImageIcon(image, size: 32, fallback: icon),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
