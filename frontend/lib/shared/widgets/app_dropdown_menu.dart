import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

import 'app_option_sheet.dart';

/// Menu thả xuống ngay dưới nút vừa bấm ([anchor] là context của nút), dùng
/// cho các danh sách chọn ngắn như sắp xếp. Nút nằm nửa phải màn hình thì
/// menu canh mép phải nút, còn lại canh mép trái; thiếu chỗ phía dưới thì mở
/// lên trên. Bấm ra ngoài để đóng, trả về null.
Future<T?> showAppDropdown<T>(
  BuildContext anchor, {
  required List<AppSheetOption<T>> options,
  T? selected,
  double minWidth = 200,
}) {
  // Mở trên navigator gần nhất (khung trang), toạ độ tính theo overlay của nó
  final navigator = Navigator.of(anchor);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final box = anchor.findRenderObject()! as RenderBox;
  final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  const itemHeight = 48.0, gap = 6.0, margin = 8.0;
  return showGeneralDialog<T>(
    context: anchor,
    useRootNavigator: false,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(anchor).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (context, _, _) {
      final size = MediaQuery.sizeOf(context);
      final width = math.min(
        math.max(minWidth, rect.width),
        size.width - margin * 2,
      );
      final height = options.length * itemHeight + 12;
      final below = size.height - rect.bottom - gap - margin;
      final openUp = below < height && rect.top > below;
      final alignRight = rect.center.dx > size.width / 2;
      final left = (alignRight ? rect.right - width : rect.left).clamp(
        margin,
        size.width - width - margin,
      );
      return Stack(
        children: [
          Positioned(
            left: left,
            width: width,
            top: openUp ? null : rect.bottom + gap,
            bottom: openUp ? size.height - rect.top + gap : null,
            child: Material(
              color: Colors.white,
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(
                    itemHeight * 3,
                    openUp ? rect.top - gap - margin : below,
                  ),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    for (final option in options)
                      _DropdownItem(
                        key: ValueKey('dropdown-${option.value}'),
                        option: option,
                        selected: option.value == selected,
                        height: itemHeight,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _DropdownItem<T> extends StatelessWidget {
  const _DropdownItem({
    super.key,
    required this.option,
    required this.selected,
    required this.height,
  });
  final AppSheetOption<T> option;
  final bool selected;
  final double height;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).pop(option.value),
    child: Container(
      height: height,
      color: selected ? const Color(0xFFF2F3F5) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (option.icon != null) ...[
            Icon(option.icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (selected)
            const Icon(AppIcons.check, size: 18, color: AppColors.textPrimary),
        ],
      ),
    ),
  );
}
