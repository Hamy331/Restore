import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Lựa chọn khi đăng trùng tin cũ đã ẩn / hết hạn
enum DuplicateListingAction { openOld, postNew }

/// Báo đã có tin giống vậy. [active]: tin cũ đang hiển thị / chờ duyệt, chỉ
/// có nút xem tin cũ. Ngược lại mời kích hoạt lại tin cũ hoặc vẫn đăng mới.
Future<DuplicateListingAction?> showDuplicateListingSheet(
  BuildContext context, {
  required bool active,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<DuplicateListingAction>(
    context,
    title: active ? l10n.duplicateActiveTitle : l10n.duplicateInactiveTitle,
    icon: AppIcons.copy,
    builder: (sheetContext) {
      void pop(DuplicateListingAction action) =>
          Navigator.of(sheetContext).pop(action);
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              active
                  ? l10n.duplicateActiveMessage
                  : l10n.duplicateInactiveMessage,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!active) ...[
                  Expanded(
                    child: AppSecondaryActionButton(
                      label: l10n.duplicatePostNew,
                      onPressed: () => pop(DuplicateListingAction.postNew),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: AppPrimaryActionButton(
                    label: l10n.duplicateOpenOld,
                    onPressed: () => pop(DuplicateListingAction.openOld),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
