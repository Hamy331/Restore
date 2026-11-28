import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Bộ nút hành động dùng chung (thanh cuối trang, nút trong sheet) để mọi
/// nút cùng chiều cao, bo góc, cỡ chữ và một tông xanh:
/// - [AppPrimaryActionButton]: nền xanh trơn, hành động chính.
/// - [AppSecondaryActionButton]: nền xanh nhạt viền xanh, hành động phụ;
///   bỏ [AppSecondaryActionButton.label] để thành nút vuông chỉ có icon.
class AppActionButtonStyle {
  AppActionButtonStyle._();

  static const double height = 52;
  static final BorderRadius radius = BorderRadius.circular(16);
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

class AppPrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppPrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final radius = AppActionButtonStyle.radius;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: AppActionButtonStyle.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: enabled || isLoading
            ? AppColors.actionPrimary
            : AppColors.border,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.actionPrimary.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: Center(
            child: isLoading
                ? const AppLoadingIndicator(
                    dotSize: 5,
                    color: AppColors.onAction,
                  )
                : _ButtonContent(
                    label: label,
                    icon: icon,
                    color: enabled
                        ? AppColors.onAction
                        : AppColors.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}

class AppSecondaryActionButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Chú thích khi chỉ có icon (đọc màn hình, nhấn giữ)
  final String? tooltip;

  const AppSecondaryActionButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppActionButtonStyle.radius;
    final enabled = onPressed != null;
    final iconOnly = label == null;
    Widget button = Material(
      color: AppColors.actionSoft.withValues(alpha: enabled ? 1 : 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: AppColors.actionPrimary.withValues(
            alpha: enabled ? 0.45 : 0.2,
          ),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: SizedBox(
          width: iconOnly ? AppActionButtonStyle.height : null,
          height: AppActionButtonStyle.height,
          child: Center(
            child: iconOnly
                ? Icon(icon, size: 18, color: AppColors.actionPrimaryDark)
                : _ButtonContent(
                    label: label!,
                    icon: icon,
                    color: AppColors.actionPrimaryDark,
                  ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Icon nhỏ + chữ, tự thu nhỏ khi nút hẹp
class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              maxLines: 1,
              style: AppActionButtonStyle.labelStyle.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút dạng link (chữ đậm màu xanh, không nền) cho thao tác phụ nằm trong nội
/// dung: "Đổi ảnh đại diện", "Thêm số", "Cập nhật", "Lên Cửa hàng"... Có
/// [icon] nhỏ phía trước nếu cần; nền xanh nhạt bo góc khi rê chuột / nhấn.
class AppLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: AppColors.actionPrimaryDark,
      disabledForegroundColor: AppColors.textSecondary,
      overlayColor: AppColors.actionPrimary,
      backgroundColor: Colors.transparent,
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      iconSize: 18,
    );
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    return icon == null
        ? TextButton(onPressed: onPressed, style: style, child: text)
        : TextButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: text,
          );
  }
}

class AppCompactActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool loading;
  const AppCompactActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary
            ? AppColors.actionSoft
            : AppColors.actionPrimary,
        foregroundColor: secondary
            ? AppColors.actionPrimaryDark
            : AppColors.onAction,
        disabledBackgroundColor: loading
            ? (secondary ? AppColors.actionSoft : AppColors.actionPrimary)
            : null,
        shape: const StadiumBorder(),
        padding: EdgeInsets.zero,
      ),
      child: loading
          ? Semantics(
              label: label,
              child: AppLoadingIndicator(
                dotSize: 5,
                color: secondary
                    ? AppColors.actionPrimaryDark
                    : AppColors.onAction,
              ),
            )
          : _ButtonContent(
              label: label,
              icon: icon,
              color: onPressed == null
                  ? AppColors.textSecondary
                  : secondary
                  ? AppColors.actionPrimaryDark
                  : AppColors.onAction,
            ),
    ),
  );
}
