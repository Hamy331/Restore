import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/listing_grid.dart';
import '../../../chat/views/chat_conversation_view.dart';
import '../fixtures/figma_preview_listings.dart';

class ProductDetailView extends StatelessWidget {
  const ProductDetailView({
    required this.listingId,
    this.isPreview = false,
    this.previewSource = 'create',
    super.key,
  });

  final String listingId;
  final bool isPreview;
  final String previewSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listing = figmaPreviewListings.firstWhere(
      (item) => item.id == listingId,
      orElse: () => figmaPreviewListings.first,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          isPreview ? l10n.listingPreviewTitle : l10n.listingDetailTitle,
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
          if (!isPreview)
            PopupMenuButton<String>(
              onSelected: (_) => context.push('/report/listing/$listingId'),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'report', child: Text(l10n.reportListing)),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: AspectRatio(
                aspectRatio: 375 / 245,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(listing.imageAsset, fit: BoxFit.cover),
                    Positioned(
                      right: 16,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: .78),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          l10n.galleryPosition(1, 5),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              child: ResponsiveContent(
                maxWidth: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      l10n.reportedListingTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.canonPrice,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.listingLocationMeta,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 22),
                    _InfoRow(
                      label: l10n.condition,
                      value: l10n.usedGoodCondition,
                    ),
                    const Divider(height: 18),
                    Text(
                      l10n.productDescription,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.canonDescription,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Divider(height: 22),
                    _SellerRow(l10n: l10n),
                    const Divider(height: 22),
                    Row(
                      children: [
                        Text(
                          l10n.similarListings,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/search'),
                          child: Text(
                            l10n.seeMore,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListingGrid(
                      listings: figmaPreviewListings.skip(1).take(2).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Align(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 728),
              child: isPreview
                  ? _PreviewActions(previewSource: previewSource, l10n: l10n)
                  : _BuyerActions(l10n: l10n),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyerActions extends StatelessWidget {
  const _BuyerActions({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/messages/minh-anh'),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: Text(l10n.chat),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 116,
        height: 48,
        child: OutlinedButton(
          onPressed: () => showMakeOfferSheet(context),
          child: Text(l10n.makeOffer),
        ),
      ),
    ],
  );
}

class _PreviewActions extends StatelessWidget {
  const _PreviewActions({required this.previewSource, required this.l10n});
  final String previewSource;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 116,
        height: 48,
        child: OutlinedButton(
          onPressed: () => context.go(
            previewSource == 'edit'
                ? '/edit-listing/camera'
                : '/create-listing',
          ),
          child: Text(previewSource == 'edit' ? l10n.editListing : l10n.back),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/manage-listings'),
            child: Text(
              previewSource == 'edit' ? l10n.saveChanges : l10n.publishListing,
            ),
          ),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class _SellerRow extends StatelessWidget {
  const _SellerRow({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/seller/minh-anh'),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.infoBg,
          child: Text(
            'MA',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sellerName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.sellerRatingMeta,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    ),
  );
}
