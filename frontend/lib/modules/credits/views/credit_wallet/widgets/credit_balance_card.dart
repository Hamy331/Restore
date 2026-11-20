import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/shared/widgets/app_image_icon.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

import '../../../models/credit_wallet.dart';
import '../../../utils/credit_format.dart';

/// Thẻ số dư: xu dùng được, chia xu nạp / xu tặng / đang giữ, nút nạp xu
class CreditBalanceCard extends StatelessWidget {
  final CreditWallet wallet;
  final VoidCallback onTopup;

  /// Bấm ô "Xu tặng": xem từng lần tặng và hạn dùng
  final VoidCallback? onBonusTap;

  const CreditBalanceCard({
    super.key,
    required this.wallet,
    required this.onTopup,
    this.onBonusTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expiry = wallet.nextBonusExpiry;
    return AppGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppImageIcon(
                AppImages.uiIcons.wallet,
                size: 40,
                fallback: AppIcons.wallet,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.creditAvailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CreditFormat.number(context, wallet.available),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.creditUnit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Part(
                label: l10n.creditPaidLabel,
                value: CreditFormat.number(context, wallet.paid),
              ),
              const SizedBox(width: 8),
              _Part(
                label: l10n.creditBonusLabel,
                value: CreditFormat.number(context, wallet.bonus),
                onTap: onBonusTap,
                tooltip: l10n.creditBonusTapHint,
              ),
              const SizedBox(width: 8),
              _Part(
                label: l10n.creditHeldLabel,
                value: CreditFormat.number(context, wallet.held),
                warning: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (expiry != null)
                l10n.creditBonusExpiry(CreditFormat.date(context, expiry)),
              l10n.creditHeldHint,
            ].join(' '),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryActionButton(
            label: l10n.creditTopupAction,
            icon: AppIcons.add,
            onPressed: onTopup,
          ),
        ],
      ),
    );
  }
}

class _Part extends StatelessWidget {
  final String label;
  final String value;
  final bool warning;
  final VoidCallback? onTap;
  final String? tooltip;

  const _Part({
    required this.label,
    required this.value,
    this.warning = false,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.textPrimary;
    final box = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warning
            ? AppColors.warningBg
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: warning
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  AppIcons.chevronRight,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
    final tap = onTap;
    return Expanded(
      child: tap == null
          ? box
          : Tooltip(
              message: tooltip ?? label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: tap,
                  child: box,
                ),
              ),
            ),
    );
  }
}
