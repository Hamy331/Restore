import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';

/// Thanh tìm kiếm dùng chung ở đầu trang kết quả tìm kiếm và trang danh mục:
/// nút quay lại, ô tìm kiếm (từ khoá đang tìm, chạm để sửa) và nút lưu tìm
/// kiếm ("Báo khi có hàng"). Trang danh mục để ô trống với chữ gợi ý như Chợ
/// Tốt, vì người dùng đang duyệt danh mục chứ không tìm từ khoá.
class AppListingSearchBar extends StatelessWidget {
  const AppListingSearchBar({
    super.key,
    required this.text,
    required this.onBack,
    required this.onEdit,
    this.onSave,
    this.isPlaceholder = false,
  });

  /// Từ khoá đang tìm, hoặc chữ gợi ý khi [isPlaceholder]
  final String text;

  /// [text] là chữ gợi ý (xám) thay vì từ khoá
  final bool isPlaceholder;
  final VoidCallback onBack;

  /// Chạm ô tìm kiếm: mở trang tìm kiếm để sửa từ khoá
  final VoidCallback onEdit;

  /// Lưu tìm kiếm, báo khi có hàng mới (null thì ẩn nút)
  final VoidCallback? onSave;

  /// Chiều cao ô tìm kiếm
  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSave = this.onSave;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
      child: Row(
        children: [
          AppCircleIconButton(
            icon: AppIcons.back,
            tooltip: l10n.back,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppSearchPill(
              text: text,
              isPlaceholder: isPlaceholder,
              height: height,
              onTap: onEdit,
              trailing: onSave == null
                  ? null
                  : IconButton(
                      tooltip: l10n.homeQuickWanted,
                      onPressed: onSave,
                      icon: const Icon(
                        Icons.bookmark_border,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
