import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/listing_grid.dart';
import '../../../../shared/widgets/feedback_view.dart';
import '../../data/listing_repository.dart';
import '../../domain/entities/listing_preview.dart';
import '../fixtures/figma_preview_listings.dart';

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({
    required this.listingId,
    this.isPreview = false,
    this.previewSource = 'create',
    this.repository,
    super.key,
  });

  final String listingId;
  final bool isPreview;
  final String previewSource;
  final ListingRepository? repository;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late final ListingRepository _repository =
      widget.repository ?? ListingRepository();
  Future<ListingPreview>? _detail;

  @override
  void initState() {
    super.initState();
    if (!widget.isPreview) _detail = _repository.get(widget.listingId);
  }

  @override
  void didUpdateWidget(ProductDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listingId != oldWidget.listingId ||
        widget.isPreview != oldWidget.isPreview) {
      _detail = widget.isPreview ? null : _repository.get(widget.listingId);
    }
  }

  void _reload() => setState(() => _detail = _repository.get(widget.listingId));

  @override
  Widget build(BuildContext context) {
    if (widget.isPreview) {
      return _buildPage(
        context,
        figmaPreviewListings.firstWhere(
          (item) => item.id == widget.listingId,
          orElse: () => figmaPreviewListings.first,
        ),
      );
    }
    return FutureBuilder<ListingPreview>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết tin đăng')),
            body: FeedbackView(
              icon: Icons.info_outline,
              title: 'Không mở được tin đăng',
              message: 'Tin có thể đã bị gỡ hoặc kết nối bị gián đoạn.',
              action: TextButton(
                onPressed: _reload,
                child: const Text('Thử lại'),
              ),
            ),
          );
        }
        return _buildPage(context, snapshot.data!);
      },
    );
  }

  Widget _buildPage(BuildContext context, ListingPreview listing) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/home?refresh=${widget.listingId}'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.isPreview ? l10n.listingPreviewTitle : l10n.listingDetailTitle,
        ),
        actions: widget.isPreview
            ? [
                IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                ),
              ]
            : null,
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
                    if (listing.imageUrl != null)
                      Image.network(
                        listing.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined),
                      ),
                    if (listing.imageUrl == null &&
                        listing.imageAsset.isNotEmpty)
                      Image.asset(listing.imageAsset, fit: BoxFit.cover),
                    if (listing.imageUrl == null && listing.imageAsset.isEmpty)
                      const Center(child: Icon(Icons.image_outlined, size: 56)),
                    if (listing.imageCount > 0)
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
                            l10n.galleryPosition(1, listing.imageCount),
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
                      listing.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.price,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (listing.isNegotiable)
                      Text(
                        l10n.negotiable,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      listing.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 22),
                    _InfoRow(label: l10n.condition, value: listing.condition),
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
                      listing.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Divider(height: 22),
                    _SellerRow(
                      l10n: l10n,
                      listing: listing,
                      isPreview: widget.isPreview,
                    ),
                    const Divider(height: 22),
                    if (widget.isPreview) ...[
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
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isPreview
          ? SafeArea(
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
                    child: _PreviewActions(
                      previewSource: widget.previewSource,
                      l10n: l10n,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
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
  const _SellerRow({
    required this.l10n,
    required this.listing,
    required this.isPreview,
  });
  final AppLocalizations l10n;
  final ListingPreview listing;
  final bool isPreview;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: isPreview ? () => context.push('/seller/minh-anh') : null,
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.infoBg,
          child: Text(
            listing.sellerName.trim().isNotEmpty
                ? listing.sellerName
                      .trim()
                      .split(' ')
                      .last
                      .substring(0, 1)
                      .toUpperCase()
                : 'MA',
            style: const TextStyle(
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
                listing.sellerName.isNotEmpty
                    ? listing.sellerName
                    : l10n.sellerName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              if (isPreview)
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
        if (isPreview)
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    ),
  );
}
