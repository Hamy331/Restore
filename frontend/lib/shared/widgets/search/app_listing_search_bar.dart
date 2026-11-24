import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Thanh tìm kiếm dùng chung ở đầu trang kết quả tìm kiếm và trang danh mục
/// (điện thoại): nền trắng, mũi tên quay lại, ô tìm kiếm xám
/// (từ khoá đang tìm, hoặc chữ gợi ý ở trang danh mục vì người dùng đang
/// duyệt chứ không tìm) và nút lưu tìm kiếm ("Báo khi có hàng") bên phải.
class AppListingSearchBar extends StatelessWidget {
  const AppListingSearchBar({
    super.key,
    required this.text,
    required this.onBack,
    required this.onEdit,
    this.onSave,
    this.isPlaceholder = false,
  }) : _input = null;

  /// Ô gõ từ khoá dùng cùng khung với ô bấm trên trang danh mục và kết quả.
  const AppListingSearchBar.editable({
    super.key,
    required this.onBack,
    required this.onEdit,
    required Widget input,
  }) : _input = input,
       text = '',
       onSave = null,
       isPlaceholder = false;

  final Widget? _input;

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
  static const double height = 44;

  /// Chiều cao cả hàng (nút quay lại / nút lưu cao 48), để tính phần ghim
  static const double rowHeight = 48;

  static const fillColor = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSave = this.onSave;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.back,
            onPressed: onBack,
            icon: const Icon(AppIcons.back, size: 24),
          ),
          Expanded(
            child: Material(
              color: fillColor,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onEdit,
                child: SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(
                        AppIcons.search,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            _input ??
                            Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                color: isPlaceholder
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                      ),
                      SizedBox(width: _input == null ? 14 : 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onSave != null)
            IconButton(
              tooltip: l10n.homeQuickWanted,
              onPressed: onSave,
              icon: const Icon(
                Icons.bookmark_border,
                size: 24,
                color: AppColors.textPrimary,
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Ô nhập từ khóa trên thanh tìm kiếm điện thoại và desktop.
class ListingSearchInput extends StatelessWidget {
  const ListingSearchInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.groupId = EditableText,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Object groupId;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        groupId: groupId,
        textAlignVertical: TextAlignVertical.center,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: l10n.searchProductsHint,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIconConstraints: const BoxConstraints.tightFor(
            width: 40,
            height: 40,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.searchClearInput,
                  icon: const Icon(
                    AppIcons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    focusNode.requestFocus();
                  },
                ),
        ),
      ),
    );
  }
}
