import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../../../models/listing_draft.dart';
import 'listing_preview_card.dart';

/// Mô tả sản phẩm và mong muốn trao đổi (nếu có)
class ListingPreviewDescriptionCard extends StatelessWidget {
  final ListingDraft draft;
  const ListingPreviewDescriptionCard({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exchangeWish = draft.exchangeWish.trim();
    return ListingPreviewCard(
      title: l10n.productDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.description.trim().isEmpty
                ? l10n.notSpecified
                : draft.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          if (draft.tradeType.allowsExchange && exchangeWish.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${l10n.exchangeWishLabel}: $exchangeWish',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
