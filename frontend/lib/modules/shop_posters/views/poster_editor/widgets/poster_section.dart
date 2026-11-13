import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Một khối của trang tạo poster: tiêu đề đậm (tuỳ chọn) rồi nội dung
class PosterSection extends StatelessWidget {
  const PosterSection({
    super.key,
    this.title,
    required this.child,
    this.last = false,
  });

  final String? title;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        child,
      ],
    ),
  );
}
