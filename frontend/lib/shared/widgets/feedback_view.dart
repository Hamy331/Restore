import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/app_image_icon.dart';

class FeedbackView extends StatelessWidget {
  const FeedbackView({
    required this.icon,
    this.image,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;

  /// Icon 3D (AppImages.uiIcons) thay cho [icon] khi có
  final String? image;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image case final image?)
              AppImageIcon(image, size: 72, fallback: icon)
            else
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
