import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import '../models/display_pricing.dart';
import '../models/posting_quota.dart';

/// Chọn ngày lúc đăng tin ([posting]: tổng số ngày + ngày bắt đầu) hay gia hạn
/// tin đang hiển thị ([extend]: số ngày thêm sau hạn hiện tại)
enum DisplayDaysMode { posting, extend }

/// Kết quả chọn: [days] là tổng số ngày (đăng tin) hoặc số ngày thêm (gia hạn)
class DisplayDaysChoice {
  final int days;
  final DateTime? startsAt;
  const DisplayDaysChoice({required this.days, this.startsAt});
}

/// Các mốc chọn nhanh (ngày thêm)
const List<int> _quickDays = [7, 15, 30, 60, 90];

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

/// Sheet chọn thời gian hiển thị. Giá tính ngay theo chuyên mục và gói
/// ([pricing]); backend tính lại khi đăng / gia hạn.
///
/// - Đăng tin: chip "Miễn phí N ngày" và "+7 … +90 ngày", nút −/+ từng ngày,
///   chọn ngày bắt đầu (hôm nay tới [DisplayPricing.maxStartDelayDays] ngày
///   tới) và ngày kết thúc trên lịch.
/// - Gia hạn: chọn số ngày thêm hoặc ngày hết hạn mới, không quá thời gian
///   tối đa của chuyên mục tính từ hôm nay. [footer] để thêm công tắc tự gia hạn.
Future<DisplayDaysChoice?> showDisplayDaysSheet(
  BuildContext context, {
  required DisplayDaysMode mode,
  required CategoryPostingQuota rule,
  required DisplayPricing pricing,
  required int walletAvailable,
  int? initialDays,
  DateTime? initialStart,
  DateTime? currentEnd,
  String? subtitle,
  Widget? footer,
  DateTime? now,
}) {
  final l = AppLocalizations.of(context)!;
  return showAppGlassSheet<DisplayDaysChoice>(
    context,
    title: mode == DisplayDaysMode.posting ? l.displayDaysTitle : l.accExtend,
    subtitle: subtitle,
    icon: AppIcons.clock,
    builder: (_) => DisplayDaysPicker(
      mode: mode,
      rule: rule,
      pricing: pricing,
      walletAvailable: walletAvailable,
      initialDays: initialDays,
      initialStart: initialStart,
      currentEnd: currentEnd,
      footer: footer,
      now: now,
    ),
  );
}

/// Nội dung sheet chọn ngày (tách riêng để test)
class DisplayDaysPicker extends StatefulWidget {
  const DisplayDaysPicker({
    super.key,
    required this.mode,
    required this.rule,
    required this.pricing,
    required this.walletAvailable,
    this.initialDays,
    this.initialStart,
    this.currentEnd,
    this.footer,
    this.now,
  });

  final DisplayDaysMode mode;
  final CategoryPostingQuota rule;
  final DisplayPricing pricing;
  final int walletAvailable;
  final int? initialDays;
  final DateTime? initialStart;
  final DateTime? currentEnd;
  final Widget? footer;
  final DateTime? now;

  @override
  State<DisplayDaysPicker> createState() => _DisplayDaysPickerState();
}

class _DisplayDaysPickerState extends State<DisplayDaysPicker> {
  late final DateTime _now = widget.now ?? DateTime.now();
  late int _days;
  DateTime? _start;

  bool get _posting => widget.mode == DisplayDaysMode.posting;
  int get _free => _posting ? widget.rule.displayDays : 0;

  /// Hạn hiện tại còn hiệu lực (gia hạn cộng tiếp từ đây)
  DateTime? get _activeEnd {
    final end = widget.currentEnd;
    return end != null && end.isAfter(_now) ? end : null;
  }

  int get _daysLeft {
    final end = _activeEnd;
    if (end == null) return 0;
    return (end.difference(_now).inMinutes / (24 * 60)).ceil();
  }

  /// Số ngày chọn được nhiều nhất: đăng tin = tối đa của chuyên mục,
  /// gia hạn = phần còn lại trước khi chạm tối đa
  int get _maxDays => _posting
      ? widget.rule.maxDisplayDays
      : (widget.rule.maxDisplayDays - _daysLeft).clamp(0, 365);

  int get _extraDays => _posting ? (_days - _free).clamp(0, 365) : _days;

  int get _credits =>
      widget.pricing.extraDaysCredits(_extraDays, widget.rule.dayPackCredits);

  DateTime get _startDay => _start ?? _now;
  DateTime get _endDate => _posting
      ? _startDay.add(Duration(days: _days))
      : (_activeEnd ?? _now).add(Duration(days: _days));

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart != null && widget.initialStart!.isAfter(_now)
        ? widget.initialStart
        : null;
    final fallback = _posting ? _free : 30;
    final max = _maxDays;
    _days = (widget.initialDays ?? fallback).clamp(max > 0 ? 1 : 0, max);
  }

  void _setDays(int value) {
    final max = _maxDays;
    setState(() => _days = value.clamp(max > 0 ? 1 : 0, max));
  }

  Future<void> _pickStart() async {
    final today = _day(_now);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day(_startDay),
      firstDate: today,
      lastDate: today.add(Duration(days: widget.pricing.maxStartDelayDays)),
    );
    if (picked == null || !mounted) return;
    setState(() => _start = picked == today ? null : picked);
  }

  Future<void> _pickEnd() async {
    final from = _day(_posting ? _startDay : (_activeEnd ?? _now));
    final picked = await showDatePicker(
      context: context,
      initialDate: _day(_endDate),
      firstDate: from.add(const Duration(days: 1)),
      lastDate: from.add(Duration(days: _maxDays)),
    );
    if (picked == null || !mounted) return;
    _setDays(picked.difference(from).inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final date = DateFormat('dd/MM/yyyy');
    final max = _maxDays;
    final pricing = widget.pricing;
    final saving = pricing.packSaving(_extraDays, widget.rule.dayPackCredits);
    final suggestion = pricing.suggestedPack(
      _extraDays,
      _posting ? max - _free : max,
      widget.rule.dayPackCredits,
    );
    final credits = _credits;
    final missing = credits - widget.walletAvailable;

    if (!_posting && max <= 0) {
      return _Padded(
        children: [
          _Note(l.extendLimitReached(widget.rule.maxDisplayDays)),
          if (widget.footer != null) ...[
            const SizedBox(height: 12),
            widget.footer!,
          ],
          const SizedBox(height: 16),
          AppSecondaryActionButton(
            label: l.postingLater,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return _Padded(
      children: [
        if (_posting)
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: l.displayDaysStart,
                  value: _start == null
                      ? l.displayDaysToday
                      : date.format(_start!),
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTile(
                  label: l.displayDaysEnd,
                  value: date.format(_endDate),
                  onTap: _pickEnd,
                ),
              ),
            ],
          )
        else ...[
          if (_activeEnd != null)
            _Note(l.extendCurrentEnd(date.format(_activeEnd!))),
          const SizedBox(height: 10),
          _DateTile(
            label: l.extendNewEnd(''),
            value: date.format(_endDate),
            onTap: _pickEnd,
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_posting)
              _DayChip(
                label: l.displayDaysFree(_free),
                selected: _days == _free,
                onTap: () => _setDays(_free),
              ),
            for (final extra in _quickDays)
              if (_free + extra <= max)
                _DayChip(
                  label: l.displayDaysPlus(extra),
                  selected: _extraDays == extra,
                  highlighted: pricing.packFor(extra) != null,
                  onTap: () => _setDays(_free + extra),
                ),
          ],
        ),
        const SizedBox(height: 14),
        _Stepper(
          label: _posting ? l.displayDaysCount : l.displayDaysExtraCount,
          value: _days,
          canDecrease: _days > 1,
          canIncrease: _days < max,
          onChanged: _setDays,
        ),
        const SizedBox(height: 14),
        _PriceBox(
          headline: credits == 0
              ? l.displayDaysNoCharge
              : l.displayDaysExtraPrice(_extraDays, credits),
          lines: [
            if (_posting) l.displayDaysIncluded(_free),
            if (saving > 0) l.displayDaysPackSave(_extraDays, saving),
            l.displayDaysMax(widget.rule.maxDisplayDays),
            if (credits > 0)
              missing > 0
                  ? '${l.postingPayBalance(widget.walletAvailable)} · '
                        '${l.postingPayMissing(missing)}'
                  : l.postingPayBalance(widget.walletAvailable),
          ],
          warn: missing > 0,
        ),
        if (suggestion != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _setDays(_free + suggestion.days),
              icon: const Icon(AppIcons.sparkle, size: 16),
              label: Text(
                l.displayDaysSuggest(suggestion.days, suggestion.credits),
              ),
            ),
          ),
        ],
        if (credits > 0) ...[
          const SizedBox(height: 6),
          Text(
            _posting ? l.displayDaysPayNote : l.extendChargeNote,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (widget.footer != null) ...[
          const SizedBox(height: 12),
          widget.footer!,
        ],
        const SizedBox(height: 16),
        AppPrimaryActionButton(
          label: _posting
              ? l.displayDaysDone
              : (missing > 0 ? l.postingTopUp : l.accExtendPay(credits)),
          icon: _posting ? AppIcons.check : AppIcons.wallet,
          onPressed: () => Navigator.of(
            context,
          ).pop(DisplayDaysChoice(days: _days, startsAt: _start)),
        ),
      ],
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      height: 1.45,
      color: AppColors.textSecondary,
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.trim().replaceAll(RegExp(r'[:\s]+$'), ''),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                AppIcons.calendar,
                size: 18,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlighted = false,
  });
  final String label;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : highlighted
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onChanged,
  });
  final String label;
  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _RoundButton(
          icon: AppIcons.minus,
          onTap: canDecrease ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 52,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _RoundButton(
          icon: AppIcons.add,
          onTap: canIncrease ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.primarySoft : AppColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.headline,
    required this.lines,
    required this.warn,
  });
  final String headline;
  final List<String> lines;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          for (final (index, line) in lines.indexed) ...[
            const SizedBox(height: 4),
            Text(
              line,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: warn && index == lines.length - 1
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
