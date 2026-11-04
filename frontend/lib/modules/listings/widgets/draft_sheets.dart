import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

/// Lựa chọn khi thoát luồng đăng tin lúc còn nội dung chưa lưu
enum LeaveDraftAction { save, discard }

/// Hỏi lưu nháp trước khi thoát. Trả về null khi người dùng đóng sheet
/// (ở lại soạn tiếp).
Future<LeaveDraftAction?> showLeaveDraftSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<LeaveDraftAction>(
    context,
    title: l10n.leaveDraftTitle,
    icon: AppIcons.saveDraft,
    builder: (sheetContext) => _SheetBody(
      message: l10n.leaveDraftMessage,
      secondary: AppSecondaryActionButton(
        label: l10n.leaveDraftDiscard,
        onPressed: () =>
            Navigator.of(sheetContext).pop(LeaveDraftAction.discard),
      ),
      primary: AppPrimaryActionButton(
        label: l10n.leaveDraftSave,
        icon: AppIcons.saveDraft,
        onPressed: () => Navigator.of(sheetContext).pop(LeaveDraftAction.save),
      ),
    ),
  );
}

/// Báo đã giữ đủ [limit] tin nháp. [onViewDrafts] (tuỳ chọn) mở trang Tin
/// nháp để xóa bớt; không có thì sheet chỉ có nút đóng.
Future<void> showDraftLimitSheet(
  BuildContext context, {
  required int? limit,
  VoidCallback? onViewDrafts,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<void>(
    context,
    title: limit == null
        ? l10n.draftLimitTitleUnknown
        : l10n.draftLimitTitle(limit),
    icon: AppIcons.saveDraft,
    builder: (sheetContext) => _SheetBody(
      message: limit == null
          ? l10n.draftLimitMessageUnknown
          : l10n.draftLimitMessage(limit),
      secondary: AppSecondaryActionButton(
        label: l10n.close,
        onPressed: () => Navigator.of(sheetContext).pop(),
      ),
      primary: onViewDrafts == null
          ? null
          : AppPrimaryActionButton(
              label: l10n.draftLimitViewDrafts,
              icon: AppIcons.listings,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onViewDrafts();
              },
            ),
    ),
  );
}

/// Xác nhận xóa tin nháp; trả về true khi đồng ý xóa
Future<bool> showDeleteDraftSheet(BuildContext context, {String? title}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAppGlassSheet<bool>(
    context,
    title: l10n.draftDeleteTitle,
    subtitle: title,
    icon: AppIcons.delete,
    builder: (sheetContext) => _SheetBody(
      message: l10n.draftDeleteMessage,
      secondary: AppSecondaryActionButton(
        label: l10n.cancel,
        onPressed: () => Navigator.of(sheetContext).pop(false),
      ),
      primary: AppPrimaryActionButton(
        label: l10n.draftDeleteConfirm,
        icon: AppIcons.delete,
        onPressed: () => Navigator.of(sheetContext).pop(true),
      ),
    ),
  );
  return confirmed ?? false;
}

class _SheetBody extends StatelessWidget {
  final String message;
  final Widget secondary;
  final Widget? primary;

  const _SheetBody({
    required this.message,
    required this.secondary,
    this.primary,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: secondary),
              if (primary case final primary?) ...[
                const SizedBox(width: 10),
                Expanded(child: primary),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
