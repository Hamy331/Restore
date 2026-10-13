import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'animations/app_collapsible.dart';
import 'glass/app_glass_container.dart';

/// Thanh tiến trình nhiều bước dạng phân đoạn, đặt trong thẻ kính:
/// "BƯỚC 2/3" + tên bước, các đoạn tô dần từ bước trước sang bước hiện tại
/// và nhãn ngắn của từng bước bên dưới.
///
/// [compact] (khi nội dung đã cuộn) thu gọn thẻ: ẩn dòng "BƯỚC n/total" và
/// nhãn từng bước, chỉ giữ tên bước, huy hiệu "n/total" và thanh tiến trình.
class AppStepIndicator extends StatelessWidget {
  /// Bước hiện tại, bắt đầu từ 1
  final int currentStep;

  /// Bước vừa rời khỏi, dùng làm điểm bắt đầu animation (mặc định bước trước)
  final int? fromStep;
  final String stepTitle;

  /// Nhãn ngắn của tất cả các bước, độ dài chính là tổng số bước
  final List<String> stepLabels;
  final bool compact;

  const AppStepIndicator({
    super.key,
    required this.currentStep,
    required this.stepTitle,
    required this.stepLabels,
    this.fromStep,
    this.compact = false,
  }) : assert(currentStep >= 1 && currentStep <= stepLabels.length);

  int get totalSteps => stepLabels.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final begin = (fromStep ?? currentStep - 1).clamp(0, totalSteps);
    final nextLabel = currentStep < totalSteps ? stepLabels[currentStep] : null;

    return AppGlassContainer(
      // Khi thu gọn, thẻ nằm trên lớp kính đầu trang nên không cần bóng
      showShadow: !compact,
      child: AnimatedPadding(
        duration: AppAnimationDurations.normal,
        curve: AppAnimationDurations.enterCurve,
        padding: compact
            ? const EdgeInsets.fromLTRB(16, 10, 12, 12)
            : const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCollapsible(
              visible: !compact,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      l10n
                          .stepProgressLabel(currentStep, totalSteps)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    if (nextLabel != null)
                      Flexible(
                        child: Text(
                          l10n.nextStepLabel(nextLabel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppAnimationDurations.normal,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      stepTitle,
                      key: ValueKey(stepTitle),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                AppCollapsible(
                  visible: compact,
                  axis: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _StepCountPill(
                      current: currentStep,
                      total: totalSteps,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedContainer(
              duration: AppAnimationDurations.normal,
              height: compact ? 10 : 12,
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: begin.toDouble(),
                end: currentStep.toDouble(),
              ),
              duration: AppAnimationDurations.slow + AppAnimationDurations.fast,
              curve: Curves.easeInOutCubic,
              builder: (context, progress, _) => Row(
                children: [
                  for (var i = 0; i < totalSteps; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _StepSegment(
                        fill: (progress - i).clamp(0.0, 1.0),
                        label: stepLabels[i],
                        showLabel: !compact,
                        state: i + 1 < currentStep
                            ? _SegmentState.done
                            : i + 1 == currentStep
                            ? _SegmentState.current
                            : _SegmentState.upcoming,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCountPill extends StatelessWidget {
  final int current;
  final int total;

  const _StepCountPill({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$current/$total',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

enum _SegmentState { done, current, upcoming }

class _StepSegment extends StatelessWidget {
  final double fill;
  final String label;
  final bool showLabel;
  final _SegmentState state;

  const _StepSegment({
    required this.fill,
    required this.label,
    required this.showLabel,
    required this.state,
  });

  static const double _height = 6;
  static const LinearGradient _fillGradient = LinearGradient(
    colors: [AppColors.primary, Color(0xFFF08A3C)],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_height),
          child: SizedBox(
            height: _height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(gradient: _fillGradient),
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppCollapsible(
          visible: showLabel,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: AppAnimationDurations.fast,
                  child: state == _SegmentState.done
                      ? const Padding(
                          key: ValueKey('done'),
                          padding: EdgeInsets.only(right: 3),
                          child: Icon(
                            AppIcons.checkCircleActive,
                            size: 12,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('todo')),
                ),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: AppAnimationDurations.normal,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: state == _SegmentState.current
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: switch (state) {
                        _SegmentState.done => AppColors.primaryDark,
                        _SegmentState.current => AppColors.textPrimary,
                        _SegmentState.upcoming => AppColors.textSecondary,
                      },
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
