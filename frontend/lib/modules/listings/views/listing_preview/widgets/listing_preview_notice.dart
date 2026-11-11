import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Dải thông báo đang ở chế độ xem trước, kèm số ngày tin được hiển thị
/// theo chuyên mục ([displayDays], null khi chưa tải được hạn mức)
class ListingPreviewNotice extends StatelessWidget {
  const ListingPreviewNotice({super.key, this.displayDays});

  final int? displayDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(AppIcons.visible, l10n.previewNotice),
          if (displayDays != null) ...[
            const SizedBox(height: 8),
            _line(AppIcons.clock, l10n.previewDisplayDays(displayDays!)),
          ],
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.primaryDark),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.primaryDark),
        ),
      ),
    ],
  );
}
