import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ListingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ListingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$currentStep/$totalSteps',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompletedOrCurrent = index < currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index == totalSteps - 1 ? 0 : 8.0,
                ),
                decoration: BoxDecoration(
                  color: isCompletedOrCurrent
                      ? AppColors.primary
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
