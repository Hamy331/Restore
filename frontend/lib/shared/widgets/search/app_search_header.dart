import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';

/// Đầu các trang tìm kiếm (tìm tin, chọn khu vực...): nền cam kem như trang
/// chủ, nút quay lại tròn trắng và ô tìm kiếm [child] chiếm phần còn lại.
/// Tự chừa thanh trạng thái phía trên.
class AppSearchHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Widget child;

  const AppSearchHeader({super.key, required this.onBack, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppHeaderPalette.gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 14),
          child: Row(
            children: [
              AppCircleIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                onTap: onBack,
              ),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
