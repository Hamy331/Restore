import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_page_header.dart';

import '../../../widgets/shop_verification_badge.dart';

/// Đầu trang shop, cùng kiểu Gần bạn / Báo khi có hàng: nút quay lại, tên
/// shop kèm loại xác minh và nút xem chứng nhận
class ShopDetailTopBar extends StatelessWidget {
  /// null khi chưa tải xong thông tin shop
  final ShopModel? shop;
  final VoidCallback onBack;
  final VoidCallback onCertificateTap;

  const ShopDetailTopBar({
    super.key,
    required this.shop,
    required this.onBack,
    required this.onCertificateTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = this.shop;
    final type = shop?.verificationType;

    return AppPageHeader(
      title: shop?.name ?? '',
      subtitle: type?.label(l10n) ?? shop?.tagline,
      onBack: onBack,
      trailing: AppCircleIconButton(
        icon: AppIcons.shield,
        tooltip: l10n.shopCertificateTitle,
        iconColor: ShopVerificationStyle.of(type).accent,
        onTap: shop == null ? null : onCertificateTap,
      ),
    );
  }
}
