import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/category_detail/repositories/category_listings_repository.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';

class ProductSimilarListings extends StatefulWidget {
  const ProductSimilarListings({
    super.key,
    required this.listingId,
    required this.categoryId,
    required this.scrollController,
  });

  final String listingId;
  final String categoryId;
  final ScrollController scrollController;

  @override
  State<ProductSimilarListings> createState() => _ProductSimilarListingsState();
}

class _ProductSimilarListingsState extends State<ProductSimilarListings> {
  static const _batchSize = 6;
  static const _limit = 20;
  final _repository = ApiCategoryListingsRepository();
  final _listings = <ListingCardItem>[];
  final _seen = <String>{};
  int _visible = 0;
  int _nextPage = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _seen.add(widget.listingId);
    widget.scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final position = widget.scrollController.position;
    if (!_failed &&
        position.userScrollDirection == ScrollDirection.reverse &&
        position.extentAfter < 120) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading ||
        _visible >= _limit ||
        (!_hasMore && _visible >= _listings.length)) {
      return;
    }
    final target = (_visible + _batchSize).clamp(0, _limit);
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      while (_hasMore && _listings.length < target) {
        final page = await _repository.getListings(
          ListingFilter(categoryId: widget.categoryId),
          page: _nextPage,
        );
        if (!mounted) return;
        for (final item in page.items) {
          if (_seen.add(item.listing.id)) _listings.add(item);
          if (_listings.length == _limit) break;
        }
        _nextPage++;
        _hasMore = page.hasMore && page.items.isNotEmpty;
      }
      _visible = target.clamp(0, _listings.length);
    } catch (_) {
      _failed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  final _saving = <String>{};

  void _updateFavorite(String id, bool favorite) {
    final index = _listings.indexWhere((item) => item.listing.id == id);
    setState(
      () => _listings[index] = _listings[index].copyWith(isFavorite: favorite),
    );
  }

  Future<void> _favorite(ListingCardItem item) async {
    if (!context.isSignedIn) {
      context.go(loginPath(from: '/listings/${widget.listingId}'));
      return;
    }
    final id = item.listing.id;
    if (!_saving.add(id)) return;
    _updateFavorite(id, !item.isFavorite);
    try {
      await _repository.setFavorite(id, !item.isFavorite);
    } catch (_) {
      if (mounted) _updateFavorite(id, item.isFavorite);
    } finally {
      _saving.remove(id);
    }
  }

  Future<void> _open(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (mounted && favorite != null) _updateFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverMainAxisGroup(
      slivers: [
        if (_visible > 0 || _loading || _failed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.similarListings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (_visible > 0)
          AppListingSliverGrid(
            items: _listings.take(_visible).toList(),
            itemBuilder: (_, item) => AppListingCard(
              item: item,
              onTap: () => _open(item),
              onFavoriteTap: () => _favorite(item),
            ),
          ),
        if (_loading)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),
        if (_failed)
          SliverToBoxAdapter(
            child: TextButton(onPressed: _load, child: Text(l10n.retry)),
          ),
      ],
    );
  }
}
