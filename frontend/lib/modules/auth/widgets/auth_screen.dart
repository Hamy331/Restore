import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    required this.child,
    this.title,
    this.onBack,
    this.centerContent = false,
    this.bottom,
    this.backgroundColor = AppColors.surface,
    super.key,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final bool centerContent;
  final Widget? bottom;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final tablet = width >= 600;
    final body = Material(
      color: backgroundColor,
      borderRadius: tablet ? BorderRadius.circular(16) : BorderRadius.zero,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tablet ? 520 : double.infinity),
        child: Column(
          children: [
            if (title != null)
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, size: 23),
                    ),
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: centerContent
                        ? (tablet
                              ? 520
                              : MediaQuery.sizeOf(context).height - 160)
                        : 0,
                  ),
                  child: centerContent ? Center(child: child) : child,
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: tablet ? AppColors.background : backgroundColor,
      body: SafeArea(
        child: tablet
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      width: 520,
                      height: (height - 56).clamp(0, 812).toDouble(),
                      child: body,
                    ),
                  ),
                ),
              )
            : body,
      ),
    );
  }
}
