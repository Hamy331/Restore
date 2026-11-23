import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import '../../../repositories/listings_repository.dart' show ContentFlag;

/// Báo nội dung tin có SĐT, link hoặc từ ngữ hàng cấm. Trả về true khi người
/// dùng vẫn muốn gửi duyệt, false / null khi muốn sửa lại.
Future<bool?> showContentFlagSheet(
  BuildContext context, {
  required List<ContentFlag> flags,
}) {
  final l10n = AppLocalizations.of(context)!;
  String label(String code) => switch (code) {
    'CONTACT' => l10n.contentFlagContact,
    'LINK' => l10n.contentFlagLink,
    _ => l10n.contentFlagBanned,
  };
  return showAppGlassSheet<bool>(
    context,
    title: l10n.contentFlagTitle,
    icon: AppIcons.warning,
    builder: (sheetContext) {
      const body = TextStyle(
        fontSize: 14,
        height: 1.45,
        color: AppColors.textSecondary,
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.contentFlagMessage, style: body),
            const SizedBox(height: 8),
            for (final flag in flags)
              Text('• ${label(flag.code)}: “${flag.match}”', style: body),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryActionButton(
                    label: l10n.contentFlagSendAnyway,
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppPrimaryActionButton(
                    label: l10n.contentFlagEdit,
                    onPressed: () => Navigator.of(sheetContext).pop(false),
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
