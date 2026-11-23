import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/thousands_separator_input_formatter.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Mở một bảng lọc nhỏ khi bấm chip "Giá ▾", "Hãng ▾"...:
/// màn rộng là popover nằm ngay dưới chip [anchor], điện thoại là bottom
/// sheet. [builder] dựng nội dung (thường là một [FilterPanel]), đóng bằng
/// `Navigator.pop(context, kếtQuả)`.
Future<T?> showFilterPopover<T>(
  BuildContext anchor, {
  required WidgetBuilder builder,
  double width = 360,
}) {
  final screen = MediaQuery.sizeOf(anchor);
  if (screen.width < AppDimesions.mobileWidth) {
    return showModalBottomSheet<T>(
      context: anchor,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: screen.height * 0.8),
      builder: (context) => SafeArea(top: false, child: builder(context)),
    );
  }
  final navigator = Navigator.of(anchor, rootNavigator: true);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final box = anchor.findRenderObject()! as RenderBox;
  final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  return showGeneralDialog<T>(
    context: anchor,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(anchor).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, _, _) {
      final size = MediaQuery.sizeOf(context);
      final top = rect.bottom + 6;
      return Stack(
        children: [
          Positioned(
            left: rect.left.clamp(8, math.max(8, size.width - width - 8)),
            top: top,
            width: width,
            child: Material(
              color: Colors.white,
              elevation: 10,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(240, size.height - top - 16),
                ),
                child: builder(context),
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

/// Khung chung của bảng lọc: đầu bảng (nút đóng hoặc quay lại + tiêu đề),
/// nội dung cuộn và chân bảng (Xoá lọc / Áp dụng)
class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.child,
    this.title,
    this.onBack,
    this.onClear,
    this.onApply,
    this.showApply = false,
  });

  /// null thì không có đầu bảng (VD bảng Giá)
  final String? title;

  /// Có thì đầu bảng là nút quay lại thay cho nút đóng
  final VoidCallback? onBack;
  final Widget child;
  final VoidCallback? onClear;

  /// null thì nút Áp dụng mờ (chưa đổi gì)
  final VoidCallback? onApply;

  /// Có nút Áp dụng (bảng chọn nhiều, khoảng giá). Bảng chọn một thì chạm là
  /// áp dụng ngay nên chỉ có nút Xoá lọc.
  final bool showApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = this.title;
    final hasApply = showApply || onApply != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Positioned(
                  left: 4,
                  child: IconButton(
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                    icon: Icon(
                      onBack != null ? AppIcons.back : AppIcons.close,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
        Flexible(child: child),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.filterClear,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (hasApply) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.actionPrimary,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.listingFilterApply,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Một lựa chọn trong [FilterChoicePanel]
typedef FilterChoice<T> = ({T value, String label});

/// Danh sách lựa chọn có ô "Nhập tìm …":
/// - [multiple] false: radio, chạm là áp dụng ngay (chạm lại là bỏ), chỉ có
///   nút Xoá lọc (Hãng, Màu sắc, Tình trạng...)
/// - [multiple] true: checkbox, bấm Áp dụng mới lọc (Dung lượng, Đăng bởi...)
///
/// Đóng bảng trả về tập giá trị đã chọn (rỗng là bỏ lọc), null nếu đóng ngang.
class FilterChoicePanel<T> extends StatefulWidget {
  const FilterChoicePanel({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    this.multiple = false,
  });

  final String title;
  final List<FilterChoice<T>> choices;
  final Set<T> selected;
  final bool multiple;

  @override
  State<FilterChoicePanel<T>> createState() => _FilterChoicePanelState<T>();
}

class _FilterChoicePanelState<T> extends State<FilterChoicePanel<T>> {
  late final Set<T> _picked = {...widget.selected};
  String _query = '';

  void _close(Set<T> values) => Navigator.of(context).pop(values);

  void _tap(T value) {
    if (!widget.multiple) {
      _close(widget.selected.contains(value) ? {} : {value});
      return;
    }
    setState(
      () =>
          _picked.contains(value) ? _picked.remove(value) : _picked.add(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final choices = [
      for (final choice in widget.choices)
        if (_query.isEmpty || VietnameseText.matches(choice.label, _query))
          choice,
    ];
    final changed =
        _picked.length != widget.selected.length ||
        !_picked.containsAll(widget.selected);
    return FilterPanel(
      title: widget.title,
      onClear: () => _close({}),
      showApply: widget.multiple,
      onApply: widget.multiple && changed ? () => _close({..._picked}) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.filterSearchHint(widget.title.toLowerCase()),
                prefixIcon: const Icon(AppIcons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Flexible(
            child: choices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.noMatchingOptions,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: choices.length,
                    itemBuilder: (_, index) {
                      final choice = choices[index];
                      final on = widget.multiple
                          ? _picked.contains(choice.value)
                          : widget.selected.contains(choice.value);
                      return InkWell(
                        onTap: () => _tap(choice.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  choice.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: on
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                widget.multiple
                                    ? (on
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank)
                                    : (on
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off),
                                size: 22,
                                color: on
                                    ? AppColors.actionPrimary
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Khoảng số đã chọn trong [FilterRangePanel]; hai đầu null là bỏ lọc
typedef FilterRange = ({num? min, num? max});

/// Bảng khoảng số (VD bảng Giá): thanh trượt (khi có [top]) và
/// hai ô nhập. [money] true thì ô nhập có dấu chấm nghìn và đơn vị đ.
class FilterRangePanel extends StatefulWidget {
  const FilterRangePanel({
    super.key,
    required this.min,
    required this.max,
    this.title,
    this.top,
    this.money = false,
    this.minLabel,
    this.maxLabel,
    this.unit,
  });

  final String? title;
  final num? min;
  final num? max;

  /// Đầu trên thanh trượt; null thì chỉ có ô nhập
  final num? top;
  final bool money;
  final String? minLabel;
  final String? maxLabel;
  final String? unit;

  @override
  State<FilterRangePanel> createState() => _FilterRangePanelState();
}

class _FilterRangePanelState extends State<FilterRangePanel> {
  late num? _min = widget.min;
  late num? _max = widget.max;
  late final _minController = TextEditingController(text: _format(_min));
  late final _maxController = TextEditingController(text: _format(_max));

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  String _format(num? value) {
    if (value == null) return '';
    return widget.money ? CurrencyFormatter.formatNumber(value) : '$value';
  }

  num? _parse(String text) => widget.money
      ? ThousandsSeparatorInputFormatter.parse(text)
      : num.tryParse(text);

  void _slide(num? min, num? max) {
    setState(() {
      _min = min;
      _max = max;
    });
    _minController.text = _format(min);
    _maxController.text = _format(max);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = widget.top;
    final invalid = _min != null && _max != null && _min! > _max!;
    final changed = _min != widget.min || _max != widget.max;
    final unit = widget.money ? CurrencyFormatter.vndSymbol : widget.unit;

    Widget field(String hint, TextEditingController controller, bool low) =>
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            widget.money
                ? ThousandsSeparatorInputFormatter(locale: _locale(context))
                : FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (text) => setState(() {
            if (low) {
              _min = _parse(text);
            } else {
              _max = _parse(text);
            }
          }),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            suffixText: unit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

    return FilterPanel(
      title: widget.title,
      onClear: () =>
          Navigator.of(context).pop<FilterRange>((min: null, max: null)),
      showApply: true,
      onApply: changed && !invalid
          ? () => Navigator.of(context).pop<FilterRange>((min: _min, max: _max))
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (top != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilterRangeSlider(
                  top: top,
                  min: _min,
                  max: _max,
                  money: widget.money,
                  onChanged: _slide,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: field(
                    widget.minLabel ?? l10n.listingFilterRangeFrom,
                    _minController,
                    true,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: field(
                    widget.maxLabel ?? l10n.listingFilterRangeTo,
                    _maxController,
                    false,
                  ),
                ),
              ],
            ),
            if (invalid) ...[
              const SizedBox(height: 6),
              Text(
                l10n.listingFilterRangeInvalid,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thanh trượt hai đầu 0 → [top] ("0 —— 50+ triệu"), chia 100
/// nấc (tiền làm tròn tới 10.000 đ); kéo hết về hai đầu là không giới hạn
/// (trả null).
class FilterRangeSlider extends StatefulWidget {
  const FilterRangeSlider({
    super.key,
    required this.top,
    required this.min,
    required this.max,
    required this.onChanged,
    this.money = false,
  });

  final num top;
  final num? min;
  final num? max;
  final bool money;

  /// Gọi khi thả tay (kéo chỉ đổi hiển thị của thanh trượt)
  final void Function(num? min, num? max) onChanged;

  @override
  State<FilterRangeSlider> createState() => _FilterRangeSliderState();
}

class _FilterRangeSliderState extends State<FilterRangeSlider> {
  /// Vị trí đang kéo, null khi không kéo
  RangeValues? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final FilterRangeSlider(:top, :min, :max, :money) = widget;
    final step = money
        ? math.max(10000, ((top / 100) / 10000).ceil() * 10000)
        : math.max(1, (top / 100).ceil());
    final last = step * 100;
    double clamp(num? value, num fallback) =>
        (value ?? fallback).clamp(0, last).toDouble();
    final start = clamp(min, 0);
    final end = math.max(start, clamp(max, last));
    final topLabel = money
        ? CurrencyFormatter.formatCompact(
            last,
            l10n,
            locale: Localizations.localeOf(context).toLanguageTag(),
          )
        : '$last';
    return Row(
      children: [
        const Text('0'),
        Expanded(
          child: RangeSlider(
            values: _dragging ?? RangeValues(start, end),
            max: last.toDouble(),
            divisions: 100,
            activeColor: AppColors.actionPrimary,
            onChanged: (values) => setState(() => _dragging = values),
            onChangeEnd: (values) {
              setState(() => _dragging = null);
              final low = (values.start / step).round() * step;
              final high = (values.end / step).round() * step;
              widget.onChanged(
                low <= 0 ? null : low,
                high >= last ? null : high,
              );
            },
          ),
        ),
        Text(l10n.filterPlusMax(topLabel)),
      ],
    );
  }
}
