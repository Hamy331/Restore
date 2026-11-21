import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Ô tìm kiếm dùng chung cho danh sách bài viết và cuộc trò chuyện.
class AppListSearchBar extends StatelessWidget {
  const AppListSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSearch,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSearch;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    void submit() {
      FocusScope.of(context).unfocus();
      onSearch();
    }

    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            maxLength: 200,
            onChanged: onChanged,
            onSubmitted: (_) => submit(),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: IconButton(
                tooltip: hintText,
                icon: const Icon(
                  AppIcons.search,
                  color: AppColors.textSecondary,
                ),
                onPressed: submit,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: const Icon(AppIcons.close, size: 20),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                        submit();
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: AppColors.actionPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
