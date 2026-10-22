import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/theme/app_glass.dart';

import 'app_action_buttons.dart';

/// Thanh nút kính mờ cố định ở cuối màn hình:
/// 1 nút chính, (tuỳ chọn) 1 nút phụ bên trái và [leading] ở đầu thanh
/// (VD nút icon nhắn tin). Các nút dùng chung kiểu trong app_action_buttons.
class AppBottomActionBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? secondaryIcon;
  final Widget? leading;
  final bool isLoading;

  const AppBottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon,
    this.leading,
    this.isLoading = false,
  });

  static const double buttonHeight = AppActionButtonStyle.height;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppGlass.fill,
            border: Border(top: BorderSide(color: AppGlass.stroke)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: _gap),
                  ],
                  if (secondaryLabel != null) ...[
                    Expanded(
                      child: AppSecondaryActionButton(
                        label: secondaryLabel,
                        icon: secondaryIcon,
                        onPressed: isLoading ? null : onSecondary,
                      ),
                    ),
                    const SizedBox(width: _gap),
                  ],
                  Expanded(
                    child: AppPrimaryActionButton(
                      label: primaryLabel,
                      icon: primaryIcon,
                      onPressed: onPrimary,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
