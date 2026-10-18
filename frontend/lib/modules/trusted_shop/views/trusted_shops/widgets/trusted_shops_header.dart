import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_page_header.dart';

/// Đầu trang Shop uy tín, cùng kiểu Gần bạn / Báo khi có hàng: nút quay
/// lại, tiêu đề kèm mô tả và nút giải thích cách xác minh
class TrustedShopsHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onInfoTap;

  const TrustedShopsHeader({
    super.key,
    required this.onBack,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageHeader(
      title: l10n.trustedShopsTitle,
      subtitle: l10n.trustedShopsSubtitle,
      onBack: onBack,
      trailing: AppCircleIconButton(
        icon: AppIcons.help,
        tooltip: l10n.shopVerificationSheetTitle,
        onTap: onInfoTap,
      ),
    );
  }
}
