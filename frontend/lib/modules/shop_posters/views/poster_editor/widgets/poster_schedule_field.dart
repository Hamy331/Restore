import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_choice_chips.dart';

import '../../../bloc/poster_editor_cubit.dart';

/// Ngày bắt đầu (ngay khi duyệt hoặc hẹn ngày, tối đa 14 ngày tới) và số
/// ngày chạy (3-14), kèm ngày kết thúc dự kiến
class PosterScheduleField extends StatelessWidget {
  const PosterScheduleField({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<PosterEditorCubit>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = cubit.state.startsAt;
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(Duration(days: cubit.state.limits.maxLeadDays)),
      initialDate: current ?? today.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    // hẹn ngày hôm nay = chạy ngay khi duyệt
    cubit.setStartsAt(picked.isAfter(today) ? picked : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<PosterEditorCubit>().state;
    final cubit = context.read<PosterEditorCubit>();
    final start = state.startsAt;
    final limits = state.limits;
    final format = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.spStart,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        AppChoiceChips<bool>(
          key: const ValueKey('poster-start'),
          alignment: WrapAlignment.start,
          items: [
            AppChoiceItem(false, l.spStartNow),
            AppChoiceItem(
              true,
              start == null ? l.spStartOn : format.format(start),
            ),
          ],
          selected: start != null,
          onSelected: (scheduled) =>
              scheduled ? _pickDate(context) : cubit.setStartsAt(null),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                l.spDuration,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              l.spDays(state.days),
              key: const ValueKey('poster-days'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Slider(
          key: const ValueKey('poster-days-slider'),
          value: state.days.toDouble(),
          min: limits.minDays.toDouble(),
          max: limits.maxDays.toDouble(),
          divisions: limits.maxDays - limits.minDays,
          label: l.spDays(state.days),
          activeColor: AppColors.primary,
          onChanged: (value) => cubit.setDays(value.round()),
        ),
        Row(
          children: [
            const Icon(
              AppIcons.calendar,
              size: 15,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              l.spEndsOn(format.format(state.endsAt(DateTime.now()))),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
