import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/seller_insights.dart';

/// Biểu đồ cột lượt xem theo ngày (một chuỗi số liệu, một màu). Chạm vào cột
/// để xem số liệu của ngày đó ở dòng phía trên; trục y chỉ ghi mốc cao nhất,
/// trục x ghi ngày đầu, giữa và cuối kỳ.
class InsightViewsChart extends StatelessWidget {
  const InsightViewsChart({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final List<InsightDay> days;
  final int? selected;
  final ValueChanged<int> onSelect;

  static const double _height = 140;

  /// Mốc trục y tròn số (1, 2, 5, 10, 20, 50...) không nhỏ hơn [value]
  static int niceMax(int value) {
    if (value <= 0) return 1;
    final magnitude = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toInt();
    for (final step in const [1, 2, 5, 10]) {
      if (step * magnitude >= value) return step * magnitude;
    }
    return 10 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final format = DateFormat('dd/MM');
    final top = niceMax(days.fold<int>(0, (m, d) => math.max(m, d.views)));
    final pick = selected;
    final caption = pick != null && pick < days.length
        ? l.insChartDay(
            format.format(days[pick].date),
            days[pick].views,
            days[pick].saves,
          )
        : l.insChartHint;
    final axis = const TextStyle(fontSize: 11, color: AppColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          caption,
          key: const ValueKey('ins-chart-caption'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: pick == null ? FontWeight.w400 : FontWeight.w600,
            color: pick == null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$top', style: axis),
                    Text('0', style: axis),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(
                  children: [
                    // Lưới mờ: mốc cao nhất và đường gốc
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final (index, day) in days.indexed)
                          Expanded(
                            child: _Bar(
                              key: ValueKey('ins-bar-$index'),
                              fraction: day.views / top,
                              selected: index == pick,
                              label: l.insChartDay(
                                format.format(day.date),
                                day.views,
                                day.saves,
                              ),
                              onTap: () => onSelect(index),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (days.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Row(
              children: [
                Text(format.format(days.first.date), style: axis),
                const Spacer(),
                if (days.length > 2)
                  Text(format.format(days[days.length ~/ 2].date), style: axis),
                const Spacer(),
                Text(format.format(days.last.date), style: axis),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.fraction,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final double fraction;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    selected: selected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        // Khe 2px giữa các cột
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: fraction.clamp(0.0, 1.0),
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryDark
                    : AppColors.primary.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
