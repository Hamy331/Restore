import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

/// Giới thiệu khi chưa gõ gì: tìm trước, ưng thì xem luôn, chưa có thì tạo
/// thông báo để được báo kèm đường dẫn tới tin
class WantedAlertCreateIntro extends StatelessWidget {
  /// Chiều cao header nổi phía trên
  final double topInset;

  const WantedAlertCreateIntro({super.key, this.topInset = 0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      (AppIcons.search, l10n.wantedAlertIntroStep1),
      (AppIcons.visible, l10n.wantedAlertIntroStep2),
      (AppIcons.wantedAlert, l10n.wantedAlertIntroStep3),
    ];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 24),
      children: [
        AppGlassContainer(
          color: AppColors.cream,
          borderColor: AppGlass.strokeSoft,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.wantedAlertIntroTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              for (final (index, (icon, text)) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            '${index + 1}. $text',
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
