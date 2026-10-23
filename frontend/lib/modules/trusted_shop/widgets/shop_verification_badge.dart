import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/shop_verification_type.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Màu và icon riêng của từng kiểu xác minh: chính hãng xanh dương (cùng màu
/// lối tắt "Shop uy tín" ở trang chủ), được chứng nhận xanh ngọc.
class ShopVerificationStyle {
  final Color accent;
  final Color tint;
  final IconData icon;

  const ShopVerificationStyle._({
    required this.accent,
    required this.tint,
    required this.icon,
  });

  static const ShopVerificationStyle official = ShopVerificationStyle._(
    accent: Color(0xFF2B63C6),
    tint: Color(0xFFEAF1FD),
    icon: AppIcons.verified,
  );

  static const ShopVerificationStyle certified = ShopVerificationStyle._(
    accent: Color(0xFF0E7C70),
    tint: Color(0xFFE5F5F2),
    icon: AppIcons.shield,
  );

  static ShopVerificationStyle of(ShopVerificationType? type) =>
      type == ShopVerificationType.certified ? certified : official;
}

/// Nhãn xác minh của shop.
/// - Mặc định: viên thuốc có icon + chữ ("Chính hãng", "Đã chứng nhận").
/// - [iconOnly]: chỉ icon đặc màu, đặt ngay sau tên shop.
class ShopVerificationBadge extends StatelessWidget {
  final ShopVerificationType type;
  final bool iconOnly;

  const ShopVerificationBadge({
    super.key,
    required this.type,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = ShopVerificationStyle.of(type);
    final label = type.label(l10n);

    if (iconOnly) {
      return Tooltip(
        message: label,
        child: Icon(style.icon, size: 16, color: style.accent),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: ShapeDecoration(
        color: style.tint,
        shape: StadiumBorder(
          side: BorderSide(color: style.accent.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: style.accent,
            ),
          ),
        ],
      ),
    );
  }
}
