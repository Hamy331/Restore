import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../../bloc/create_listing/create_listing_state.dart';
import '../../../models/listing_draft.dart';
import '../../../models/listing_enums.dart';
import 'listing_preview_card.dart';

/// Tiêu đề, giá, địa chỉ và các nhãn tóm tắt của tin
class ListingPreviewSummaryCard extends StatelessWidget {
  final CreateListingState state;
  const ListingPreviewSummaryCard({super.key, required this.state});

  String _priceText(AppLocalizations l10n, ListingDraft draft, String locale) {
    final price = draft.price;
    return switch (draft.tradeType) {
      TradeType.exchange => l10n.tradeExchange,
      _ when price == null => l10n.notSpecified,
      _ => CurrencyFormatter.formatVnd(price, locale: locale),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final draft = state.draft;
    final category = state.category;
    final location = draft.address?.areaLabel;
    final tags = [
      ?category?.name.of(context),
      ?draft.condition?.label(l10n),
      if (draft.tradeType.requiresPrice && draft.isNegotiable) l10n.negotiable,
      draft.sellerType == SellerType.personal
          ? l10n.sellerPersonal
          : l10n.sellerBusiness,
      if (draft.tradeType.allowsExchange) l10n.tradeExchangeAccepted,
    ];

    return ListingPreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.title.trim().isEmpty ? l10n.notSpecified : draft.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _priceText(l10n, draft, locale),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
          if (location != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  AppIcons.location,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final tag in tags) _Tag(label: tag)],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
      ),
    );
  }
}
