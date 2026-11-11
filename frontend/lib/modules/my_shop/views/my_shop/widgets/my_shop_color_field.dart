import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Màu nhận diện có sẵn để chọn (hex không dấu #)
const myShopColors = [
  '1428A0',
  '2563EB',
  '0F766E',
  '16A34A',
  'CA8A04',
  'EA580C',
  'DC2626',
  'DB2777',
  '7C3AED',
  '29231B',
];

/// Chọn màu nhận diện: "Mặc định" (theo kiểu xác minh) hoặc một màu có sẵn.
/// [value] dạng "#RRGGBB" hoặc null.
class MyShopColorField extends StatelessWidget {
  const MyShopColorField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = value?.replaceFirst('#', '').toUpperCase();
    Widget swatch({
      required Key key,
      required bool selected,
      required VoidCallback onTap,
      Color? color,
    }) => GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? AppColors.surface,
            border: color == null ? Border.all(color: AppColors.border) : null,
          ),
          child: selected
              ? Icon(
                  AppIcons.check,
                  size: 14,
                  color: color == null ? AppColors.textPrimary : Colors.white,
                )
              : null,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            swatch(
              key: const ValueKey('my-shop-color-auto'),
              selected: current == null,
              onTap: () => onChanged(null),
            ),
            for (final hex in myShopColors)
              swatch(
                key: ValueKey('my-shop-color-$hex'),
                selected: current == hex,
                color: Color(0xFF000000 | int.parse(hex, radix: 16)),
                onTap: () => onChanged('#$hex'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          current == null ? l.msColorAuto : '#$current',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
