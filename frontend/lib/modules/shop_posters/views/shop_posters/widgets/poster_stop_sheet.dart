import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Hỏi lại trước khi dừng poster đang chạy ([pending] = hủy poster chờ duyệt).
/// Trả về true khi người dùng xác nhận.
Future<bool> confirmStopPoster(
  BuildContext context, {
  required bool pending,
}) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showAppGlassSheet<bool>(
    context,
    title: pending ? l.spCancelTitle : l.spStopTitle,
    icon: AppIcons.block,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pending ? l.spCancelBody : l.spStopBody,
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
                  label: l.spKeep,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryActionButton(
                  key: const ValueKey('poster-stop-confirm'),
                  label: pending ? l.spConfirmCancel : l.spConfirmStop,
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
