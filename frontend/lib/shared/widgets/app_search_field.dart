import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    this.onTap,
    this.controller,
    this.onChanged,
    this.hintText = 'Tìm sản phẩm, cửa hàng...',
    this.showFilter = false,
    super.key,
  });

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool showFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onTap: onTap,
        onChanged: onChanged,
        readOnly: onTap != null && controller == null,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: showFilter ? const Icon(Icons.tune, size: 20) : null,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
