import 'package:restore/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';

import '../../../models/product_detail.dart';

/// Buyer contact actions and owner listing management.
class ProductDetailBottomBar extends StatelessWidget {
  final ProductDetail detail;
  final bool isSubmitting;
  final VoidCallback onChat;
  final VoidCallback onSave;
  final VoidCallback? onCall;
  final String? callLabel;
  final VoidCallback onEdit;
  final VoidCallback onBoost;
  final VoidCallback onFeature;

  const ProductDetailBottomBar({
    super.key,
    required this.detail,
    required this.isSubmitting,
    required this.onChat,
    required this.onSave,
    required this.onCall,
    this.callLabel,
    required this.onEdit,
    required this.onBoost,
    required this.onFeature,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (detail.isOwner) {
      return AppBottomActionBar(
        leading: AppSecondaryActionButton(
          icon: AppIcons.hot,
          tooltip: l10n.featureAction,
          onPressed: onFeature,
        ),
        secondaryLabel: l10n.productEditListing,
        secondaryIcon: AppIcons.edit,
        onSecondary: onEdit,
        primaryLabel: l10n.productBoost,
        primaryIcon: AppIcons.boost,
        onPrimary: onBoost,
      );
    }

    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Row(
            children: [
              TextButton(
                onPressed: onSave,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  minimumSize: const Size(48, 44),
                  padding: EdgeInsets.zero,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      detail.isFavorite
                          ? AppIcons.savedListing
                          : AppIcons.favorite,
                      color: detail.isFavorite
                          ? AppColors.error
                          : AppColors.textPrimary,
                      size: 21,
                    ),
                    Text(
                      detail.isFavorite ? l10n.listingSavedLabel : l10n.accSave,
                      style: const TextStyle(fontSize: 12, height: 1.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AppCompactActionButton(
                  label: callLabel ?? l10n.listingCall,
                  secondary: true,
                  onPressed: onCall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: AppCompactActionButton(
                  label: l10n.productChat,
                  icon: AppIcons.chat,
                  onPressed: isSubmitting ? null : onChat,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
