import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Hỏi lại trước khi xoá thông báo [keywords]; trả về true khi người dùng
/// chọn xoá. Xoá là dừng hẳn việc báo tin mới.
Future<bool> confirmDeleteWantedAlert(
  BuildContext context, {
  required String keywords,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAppGlassSheet<bool>(
    context,
    title: l10n.wantedAlertDeleteTitle,
    icon: AppIcons.delete,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.wantedAlertDeleteBody(keywords),
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppSecondaryActionButton(
                  label: l10n.wantedAlertKeep,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryActionButton(
                  label: l10n.wantedAlertDelete,
                  icon: AppIcons.delete,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}
