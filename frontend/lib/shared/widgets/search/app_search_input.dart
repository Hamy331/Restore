import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Ô nhập từ khoá dạng viên thuốc trắng, cùng kích thước và kiểu với
/// [AppSearchPill] để khi chuyển từ ô bấm sang ô gõ không bị giật.
/// Có nút xoá nhanh khi đã gõ, bàn phím hiện nút "Tìm kiếm".
class AppSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final IconData icon;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppSearchInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.icon = AppIcons.search,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  static const double height = 48;

  void _clear() {
    controller.clear();
    onChanged?.call('');
    focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: height,
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        ),
        shadows: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: 16)
                : IconButton(
                    tooltip: l10n.searchClearInput,
                    onPressed: _clear,
                    icon: const Icon(
                      AppIcons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
