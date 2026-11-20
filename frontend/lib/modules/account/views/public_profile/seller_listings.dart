import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/home/repositories/home_repository.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/listing/listing_partner_badge.dart';

class SellerListings extends StatefulWidget {
  const SellerListings({
    super.key,
    required this.userId,
    required this.summary,
    required this.refresh,
  });
  final String userId;
  final Widget summary;
  final Future<void> Function() refresh;
  @override
  State<SellerListings> createState() => _SellerListingsState();
}

class _SellerListingsState extends State<SellerListings>
    with AutomaticKeepAliveClientMixin {
  final _repo = ApiHomeRepository();
  final _items = <ListingCardItem>[];
  final _saving = <String>{};
  int _page = 1, _version = 0;
  bool _loading = false, _failed = false, _more = true;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || !_more)) return;
    final version = ++_version;
    final page = reset ? 1 : _page;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _repo.sellerListings(widget.userId, page);
      if (!mounted || version != _version) return;
      if (reset) _items.clear();
      final seen = _items.map((i) => i.listing.id).toSet();
      _items.addAll(result.items.where((i) => seen.add(i.listing.id)));
      _more = result.hasMore && result.items.isNotEmpty;
      _page = page + 1;
    } catch (_) {
      if (mounted && version == _version) _failed = true;
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  void _sync(String id, bool value) {
    final index = _items.indexWhere((i) => i.listing.id == id);
    if (mounted && index >= 0) {
      setState(() => _items[index] = _items[index].copyWith(isFavorite: value));
    }
  }

  Future<void> _favorite(ListingCardItem item) async {
    final id = item.listing.id;
    if (!_saving.add(id)) return;
    try {
      await _repo.setFavorite(id, !item.isFavorite);
      _sync(id, !item.isFavorite);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.feedActionError),
          ),
        );
      }
    } finally {
      _saving.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([widget.refresh(), _load(reset: true)]);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0 &&
              n is ScrollUpdateNotification &&
              n.metrics.extentAfter < 280 &&
              !_failed) {
            _load();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: widget.summary),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  l.sellingListings,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final item = _items[index], listing = item.listing;
                final date = listing.createdAt;
                return Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final saved = await context.push<bool>(
                          '/listings/${listing.id}',
                          extra: listing,
                        );
                        if (saved != null) _sync(listing.id, saved);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox.square(
                                dimension: 106,
                                child: listing.coverImage == null
                                    ? const ColoredBox(
                                        color: Color(0xfff5f5f5),
                                        child: Icon(Icons.image_outlined),
                                      )
                                    : AppLocalImage(
                                        path: listing.coverImage!,
                                        cacheWidth: 320,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListingCardTitle(
                                    title: listing.title,
                                    isPartner: listing.isPartner,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    listing.price == null
                                        ? l.homeExchangeOnly
                                        : CurrencyFormatter.formatVnd(
                                            listing.price!,
                                            locale: l.localeName,
                                          ),
                                    style: const TextStyle(
                                      color: Color(0xffce2854),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          [
                                                item.areaLabel,
                                                if (date != null)
                                                  TimeAgoFormatter.format(
                                                    date,
                                                    l,
                                                  ),
                                              ]
                                              .where((s) => s.isNotEmpty)
                                              .join(' · '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: item.isFavorite
                                            ? l.listingSavedLabel
                                            : l.accSave,
                                        onPressed: () => _favorite(item),
                                        icon: Icon(
                                          item.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: item.isFavorite
                                              ? Colors.red
                                              : null,
                                          size: 21,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xffeeeeee)),
                  ],
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : _failed
                      ? TextButton(onPressed: _load, child: Text(l.retry))
                      : _items.isEmpty
                      ? Text(l.followShopsListingsEmpty)
                      : _more
                      ? TextButton(onPressed: _load, child: Text(l.seeMore))
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
