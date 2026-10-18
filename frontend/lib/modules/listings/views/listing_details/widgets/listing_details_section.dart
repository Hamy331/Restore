import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/shared/widgets/app_required_label.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

/// Thẻ kính mờ có tiêu đề, gom một nhóm trường trong bước 3
class ListingDetailsSection extends StatelessWidget {
  final String title;
  final bool isRequired;
  final List<Widget> children;

  const ListingDetailsSection({
    super.key,
    required this.title,
    required this.children,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppRequiredLabel(
            text: title,
            isRequired: isRequired,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}
