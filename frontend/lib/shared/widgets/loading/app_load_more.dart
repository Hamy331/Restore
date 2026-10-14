import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import 'app_loading_indicator.dart';

/// Gọi [onLoadMore] khi người dùng cuộn gần cuối danh sách.
/// Bên gọi tự chặn gọi trùng (VD cubit bỏ qua khi đang tải hoặc đã hết).
class AppLoadMoreListener extends StatelessWidget {
  final VoidCallback onLoadMore;
  final Widget child;

  /// Còn cách cuối bao nhiêu px thì bắt đầu tải trang tiếp
  final double threshold;

  const AppLoadMoreListener({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = 480,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.vertical &&
            notification.depth == 0 &&
            metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// Chân danh sách: hiện loading khi đang tải trang tiếp,
/// hoặc dòng [endText] khi đã hết dữ liệu.
class AppLoadMoreFooter extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final String? endText;

  const AppLoadMoreFooter({
    super.key,
    required this.isLoading,
    required this.hasMore,
    this.endText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const Padding(
              key: ValueKey('loading'),
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppLoadingIndicator()),
            )
          : !hasMore && endText != null
          ? Padding(
              key: const ValueKey('end'),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      endText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
            )
          : const SizedBox(key: ValueKey('idle'), height: 24),
    );
  }
}
