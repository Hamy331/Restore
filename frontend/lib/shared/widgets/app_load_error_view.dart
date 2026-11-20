import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/animations/fade_slide_in.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

/// Trạng thái lỗi tải dữ liệu dùng chung cho mọi trang.
///
/// Mặc định dùng bộ chuỗi chung ([AppLocalizations.loadErrorTitle],
/// [AppLocalizations.loadErrorBody]); trang nào cần nói rõ hơn thì truyền
/// [title] riêng. [onRetry] trả về Future thì nút Thử lại tự hiện loading
/// cho tới khi xong.
class AppLoadErrorView extends StatefulWidget {
  const AppLoadErrorView({
    this.onRetry,
    this.title,
    this.message,
    this.icon = AppIcons.offline,
    this.compact = false,
    super.key,
  });

  final FutureOr<void> Function()? onRetry;
  final String? title;
  final String? message;
  final IconData icon;

  /// Bản gọn cho khối nhỏ nằm trong trang (VD một section), không chiếm cả màn
  final bool compact;

  @override
  State<AppLoadErrorView> createState() => _AppLoadErrorViewState();
}

class _AppLoadErrorViewState extends State<AppLoadErrorView> {
  bool _retrying = false;

  Future<void> _retry() async {
    final onRetry = widget.onRetry;
    if (onRetry == null || _retrying) return;
    final result = onRetry();
    if (result is! Future) return;
    setState(() => _retrying = true);
    try {
      await result;
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final compact = widget.compact;
    final badgeSize = compact ? 64.0 : 96.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: compact ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBadge(icon: widget.icon, size: badgeSize),
                SizedBox(height: compact ? 12 : 20),
                Text(
                  widget.title ?? l10n.loadErrorTitle,
                  textAlign: TextAlign.center,
                  style:
                      (compact
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.message ?? l10n.loadErrorBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (widget.onRetry != null) ...[
                  SizedBox(height: compact ? 14 : 24),
                  _RetryButton(
                    label: l10n.retry,
                    loading: _retrying,
                    compact: compact,
                    onPressed: _retry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon trong vòng kính, chỉ một bóng mảnh bên dưới (không quầng cam mờ)
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGlass.sheen(),
        border: Border.all(color: AppGlass.stroke, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.42, color: AppColors.primaryDark),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.label,
    required this.loading,
    required this.compact,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
        disabledForegroundColor: Colors.white,
        minimumSize: Size(compact ? 120 : 148, compact ? 40 : 46),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: loading
            ? const AppLoadingIndicator(
                key: ValueKey('loading'),
                dotSize: 5,
                color: Colors.white,
              )
            : Row(
                key: const ValueKey('label'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.refresh, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
