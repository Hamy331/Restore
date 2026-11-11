import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

import '../../../../listings/widgets/boost_listing_sheet.dart'
    show popSheetOnce;

/// Hỏi lại trước khi trừ xu / dùng lượt tặng. Trả về true khi đồng ý.
/// [balanceAfter] null thì không hiện dòng số xu còn lại (lượt miễn phí).
Future<bool> showPromotionConfirmSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required String message,
  required String confirmLabel,
  int? balanceAfter,
}) async =>
    await showAppGlassSheet<bool>(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext)!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              if (balanceAfter != null) ...[
                const SizedBox(height: 10),
                Text(
                  l.promoBalanceAfter(balanceAfter),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryActionButton(
                      label: l.postingLater,
                      onPressed: () => popSheetOnce(sheetContext, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppPrimaryActionButton(
                      key: const ValueKey('promo-confirm'),
                      label: confirmLabel,
                      icon: icon,
                      onPressed: () => popSheetOnce(sheetContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ) ==
    true;
