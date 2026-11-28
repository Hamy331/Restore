import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import '../../../repositories/listing_ai_repository.dart';

/// Gợi ý AI soạn từ ảnh bìa: xem trước tiêu đề, tình trạng, mô tả, kèm cảnh
/// báo khi AI nghi hàng cấm. [categoryLabel]: danh mục AI chọn (null khi giữ
/// nguyên danh mục). Trả về true khi người dùng muốn dùng gợi ý.
Future<bool?> showAiSuggestionSheet(
  BuildContext context, {
  required ListingAiSuggestion suggestion,
  required bool vehicle,
  String? categoryLabel,
}) {
  final l10n = AppLocalizations.of(context)!;
  final condition = suggestion.condition;
  return showAppGlassSheet<bool>(
    context,
    title: l10n.aiComposeTitle,
    icon: AppIcons.sparkle,
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
            if (suggestion.prohibited) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(AppIcons.warning, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.aiComposeProhibited(suggestion.reason),
                        style: body.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (suggestion.title.isNotEmpty)
              Text(
                suggestion.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            if (categoryLabel != null) ...[
              const SizedBox(height: 4),
              Text('${l10n.aiComposeCategory}: $categoryLabel', style: body),
            ],
            if (condition != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.conditionLabel}: ${condition.labelFor(l10n, vehicle: vehicle)}',
                style: body,
              ),
            ],
            if (suggestion.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(suggestion.description, style: body),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(l10n.aiComposeNote, style: body.copyWith(fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryActionButton(
                    label: l10n.cancel,
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppPrimaryActionButton(
                    label: l10n.aiComposeApply,
                    onPressed: () => Navigator.of(sheetContext).pop(true),
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
