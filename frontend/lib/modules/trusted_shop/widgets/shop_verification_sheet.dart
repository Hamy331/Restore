import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/shop_verification_type.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

import 'shop_verification_badge.dart';

/// Sheet giải thích hai kiểu xác minh shop. Truyền [shop] để hiện thêm
/// chứng nhận của shop đó (mã, ngày xác minh) ở đầu sheet.
Future<void> showShopVerificationSheet(
  BuildContext context, {
  ShopModel? shop,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<void>(
    context,
    title: l10n.shopVerificationSheetTitle,
    subtitle: l10n.shopVerificationSheetSubtitle,
    icon: AppIcons.shield,
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shop != null && shop.verificationType != null) ...[
            _ShopCertificate(shop: shop),
            const SizedBox(height: 16),
          ],
          for (final type in ShopVerificationType.values) ...[
            _VerificationTypeTile(type: type),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.info,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.shopVerificationSheetNote,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _VerificationTypeTile extends StatelessWidget {
  final ShopVerificationType type;

  const _VerificationTypeTile({required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = ShopVerificationStyle.of(type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, size: 18, color: style.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label(l10n),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: style.accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type.description(l10n),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ chứng nhận của một shop: kiểu xác minh, mã chứng nhận, ngày cấp
class _ShopCertificate extends StatelessWidget {
  final ShopModel shop;

  const _ShopCertificate({required this.shop});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final style = ShopVerificationStyle.of(shop.verificationType);
    final verifiedAt = shop.verifiedAt;
    final code = shop.certificateCode;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.tint, Colors.white.withValues(alpha: 0.8)],
        ),
        border: Border.all(color: style.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 18, color: style.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ShopVerificationBadge(type: shop.verificationType!),
            ],
          ),
          if (code != null) row(l10n.shopCertificateCode, code),
          if (verifiedAt != null)
            row(
              l10n.shopVerifiedSince,
              DateFormat.yMd(locale).format(verifiedAt.toLocal()),
            ),
        ],
      ),
    );
  }
}
