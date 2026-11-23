import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Chọn ngày mở cửa (T2-CN) và một khung giờ dùng chung cho các ngày đã chọn
class MyShopHoursField extends StatelessWidget {
  const MyShopHoursField({
    super.key,
    required this.days,
    required this.open,
    required this.close,
    required this.onDaysChanged,
    required this.onOpenChanged,
    required this.onCloseChanged,
  });

  /// Thứ đã chọn theo `DateTime.weekday` (1 = thứ Hai)
  final Set<int> days;
  final TimeOfDay open, close;
  final ValueChanged<Set<int>> onDaysChanged;
  final ValueChanged<TimeOfDay> onOpenChanged, onCloseChanged;

  static String format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  /// Khung giờ hợp lệ: mở trước đóng
  static bool valid(TimeOfDay open, TimeOfDay close) =>
      _minutes(open) < _minutes(close);

  Future<void> _pick(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final showError = days.isNotEmpty && !valid(open, close);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                key: ValueKey('my-shop-day-$day'),
                label: Text(l.msWeekdayShort('$day')),
                selected: days.contains(day),
                showCheckmark: false,
                selectedColor: AppColors.primarySoft,
                onSelected: (selected) => onDaysChanged(
                  selected ? {...days, day} : ({...days}..remove(day)),
                ),
              ),
          ],
        ),
        if (days.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  key: const ValueKey('my-shop-open-time'),
                  label: l.msHoursOpen,
                  value: format(open),
                  onTap: () => _pick(context, open, onOpenChanged),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeButton(
                  key: const ValueKey('my-shop-close-time'),
                  label: l.msHoursClose,
                  value: format(close),
                  onTap: () => _pick(context, close, onCloseChanged),
                ),
              ),
            ],
          ),
        ],
        if (showError) ...[
          const SizedBox(height: 6),
          Text(
            l.msHoursInvalid,
            style: const TextStyle(fontSize: 12.5, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(AppIcons.clock, size: 16),
    label: Text('$label  $value'),
  );
}
