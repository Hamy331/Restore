import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: SizedBox(
      width: double.infinity,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class AdminHeading extends StatelessWidget {
  const AdminHeading(this.title, this.description, {this.action, super.key});
  final String title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 6),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        if (action != null) action!,
      ],
    ),
  );
}

class AdminBadge extends StatelessWidget {
  const AdminBadge(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    final danger = [
      'Đã gỡ',
      'Từ chối',
      'Đã cấm',
      'Thất bại',
      'Lỗi kích hoạt',
    ].contains(label);
    final good = [
      'Đang hiển thị',
      'Hoạt động',
      'Đã giải quyết',
      'Thành công',
      'Đang chạy',
      'Đang bán',
      'Đã xuất bản',
      'Đã đồng bộ',
    ].contains(label);
    final neutral = [
      'Đã bác bỏ',
      'Hết hạn',
      'Tạm ngừng',
      'Lưu trữ',
      'Đang ẩn',
    ].contains(label);
    final color = danger
        ? AppColors.error
        : good
        ? AppColors.success
        : neutral
        ? AppColors.textSecondary
        : AppColors.warning;
    final background = danger
        ? AppColors.errorBg
        : good
        ? AppColors.successBg
        : neutral
        ? AppColors.background
        : AppColors.warningBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AdminButton extends StatelessWidget {
  const AdminButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.primary = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger, primary;
  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label)),
      ],
    );
    final style = OutlinedButton.styleFrom(
      foregroundColor: danger ? AppColors.error : AppColors.textPrimary,
      backgroundColor: primary ? AppColors.primary : AppColors.surface,
      side: BorderSide(
        color: danger
            ? AppColors.error
            : primary
            ? AppColors.primary
            : AppColors.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class AdminSelect extends StatelessWidget {
  const AdminSelect({
    required this.value,
    required this.values,
    required this.onChanged,
    required this.label,
    super.key,
  });
  final String value, label;
  final List<String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        for (final item in values)
          DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

class AdminSearch extends StatelessWidget {
  const AdminSearch({
    required this.onChanged,
    this.hint = 'Tìm kiếm...',
    super.key,
  });
  final ValueChanged<String> onChanged;
  final String hint;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
      ),
    ),
  );
}
