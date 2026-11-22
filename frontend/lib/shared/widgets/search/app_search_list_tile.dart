import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Một dòng trong trang tìm kiếm: gợi ý, lịch sử, khu vực...
///
/// - [icon]: null thì không có icon, chữ sát lề trái (gợi ý tìm nhanh).
/// - [boxed]: icon nằm trong ô vuông bo góc (lịch sử, khu vực); false thì
///   chỉ hiện icon nhỏ (gợi ý từ khoá).
/// - [highlight]: tô đậm phần khớp với từ khoá đang gõ (so không dấu).
/// - [onRemove]: nút thùng rác bên phải (xoá khỏi lịch sử).
/// - [onFill]: nút mũi tên đưa nội dung lên ô tìm kiếm để sửa tiếp.
class AppSearchListTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? highlight;
  final bool boxed;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onFill;

  const AppSearchListTile({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.highlight,
    this.boxed = false,
    this.iconColor = AppColors.textSecondary,
    this.onRemove,
    this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = this.subtitle;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          boxed ? 8 : 4,
          onRemove == null && onFill == null ? 16 : 4,
          boxed ? 8 : 4,
        ),
        child: Row(
          children: [
            if (icon == null)
              const SizedBox(height: 40)
            else if (boxed)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              )
            else
              SizedBox(
                width: 24,
                height: 40,
                child: Icon(icon, size: 18, color: iconColor),
              ),
            if (icon != null) SizedBox(width: boxed ? 12 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    _titleSpan(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onFill != null)
              IconButton(
                tooltip: l10n.searchFillQuery,
                onPressed: onFill,
                icon: const Icon(
                  AppIcons.fillQuery,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            if (onRemove != null)
              IconButton(
                tooltip: l10n.searchRemoveHistory,
                onPressed: onRemove,
                icon: const Icon(
                  AppIcons.delete,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  TextSpan _titleSpan() => highlightSpan(
    title,
    highlight,
    const TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
  );

  /// [text] với phần khớp [query] (so không dấu) tô đậm, phần còn lại nhạt
  /// hơn; không khớp thì giữ nguyên kiểu [base]
  static TextSpan highlightSpan(String text, String? query, TextStyle base) {
    final range = query == null ? null : VietnameseText.matchRange(text, query);
    if (range == null) return TextSpan(text: text, style: base);
    final (start, end) = range;
    return TextSpan(
      style: base.copyWith(color: AppColors.textSecondary),
      children: [
        TextSpan(text: text.substring(0, start)),
        TextSpan(
          text: text.substring(start, end),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        TextSpan(text: text.substring(end)),
      ],
    );
  }
}
