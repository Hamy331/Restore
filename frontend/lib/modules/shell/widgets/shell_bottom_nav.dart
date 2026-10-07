import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';

class ShellBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ShellBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home, l10n.homeTitle),
      (Icons.inventory_2_outlined, Icons.inventory_2, l10n.manageListings),
      (Icons.add, Icons.add, l10n.createListing),
      (Icons.chat_bubble_outline, Icons.chat_bubble, l10n.messagesTitle),
      (Icons.person_outline, Icons.person, l10n.accountTitle),
    ];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 65,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = index == selectedIndex;
                    final color = selected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary;

                    // --- XỬ LÝ RIÊNG NÚT ĐĂNG TIN (GIỮA) ---
                    if (index == 2) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onSelected(index),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.$3,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    }

                    // --- CÁC NÚT TAB BÌNH THƯỜNG ---
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: item.$3,
                        child: GestureDetector(
                          onTap: () => onSelected(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: Colors.transparent, // Mở rộng khu vực bấm
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // 1. Hiệu ứng nảy (Bounce) cho Icon
                                AnimatedScale(
                                  scale: selected
                                      ? 1.15
                                      : 1.0, // Phóng to 15% khi chọn
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves
                                      .easeOutBack, // Đường cong tạo độ "nảy"
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        selected ? item.$2 : item.$1,
                                        size: 25,
                                        color: color,
                                      ),
                                      if (index == 3)
                                        Positioned(
                                          right: -6,
                                          top: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFD93F11),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Text(
                                              '3',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                height: 1,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // 2. Hiệu ứng chuyển màu mượt mà & Chống cắt chữ
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit
                                        .scaleDown, // Tự động thu nhỏ nếu text quá dài
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: color,
                                        fontFamily: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.fontFamily, // Giữ font mặc định
                                      ),
                                      child: Text(item.$3, maxLines: 1),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // --- NÚT LỒI ĐĂNG TIN (+) ---
            Positioned(
              top: -18,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => onSelected(2),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 32,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
