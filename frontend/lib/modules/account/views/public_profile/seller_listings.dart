import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/filter/listing_filter_labels.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/home/repositories/home_repository.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/listing/listing_partner_badge.dart';
import 'package:restore/modules/listings/views/product_detail/product_detail_view.dart';

class SellerListings extends StatefulWidget {
  const SellerListings({
    super.key,
    required this.userId,
    required this.summary,
    required this.refresh,
    this.grid = false,
    this.searchable = false,
    this.activeCount = 0,
    this.soldCount = 0,
  });
  final String userId;
  final Widget summary;

  /// Desktop / cửa hàng: tin đăng dạng lưới thẻ (như trang danh mục) thay vì
  /// danh sách
  final bool grid;

  /// Tổng số tin, chip Đang bán / Đã bán, ô tìm và nút sắp xếp
  final bool searchable;

  /// Số tin đang bán / đã bán (từ hồ sơ) cho tiêu đề và chip lọc
  final int activeCount, soldCount;
  final Future<void> Function() refresh;
  @override
  State<SellerListings> createState() => _SellerListingsState();
}

class _SellerListingsState extends State<SellerListings>
    with AutomaticKeepAliveClientMixin {
  final _repo = ApiHomeRepository();
  final _items = <ListingCardItem>[];
  final _saving = <String>{};
  final _search = TextEditingController();
  int _page = 1, _version = 0;
  bool _loading = false, _failed = false, _more = true, _sold = false;
  String _query = '';
  ListingSort _sort = ListingSort.newest;
  Timer? _debounce;

  static const _sorts = [
    ListingSort.newest,
    ListingSort.priceLow,
    ListingSort.priceHigh,
  ];

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Gõ xong 400ms mới tìm, tránh gọi API mỗi phím
  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      if (query == _query) return;
      _query = query;
      _load(reset: true);
    });
  }

  Future<void> _pickSort(BuildContext anchor) async {
    final picked = await showListingSortSheet(
      anchor,
      selected: _sort,
      options: _sorts,
    );
    if (picked == null || picked == _sort) return;
    _sort = picked;
    _load(reset: true);
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
      final result = await _repo.sellerListings(
        widget.userId,
        page,
        query: _query,
        sort: _sort == ListingSort.newest ? null : _sort.apiValue,
        sold: _sold,
      );
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

  Future<void> _open(ListingCardItem item) async {
    final listing = item.listing;
    final saved = await context.push<bool>(
      ProductDetailView.location(
        listing.id,
        title: listing.title,
        shortId: listing.shortId,
      ),
      extra: listing,
    );
    if (saved != null) _sync(listing.id, saved);
  }

  void _showSold(bool sold) {
    if (_sold == sold) return;
    _sold = sold;
    _load(reset: true);
  }

  /// "Tất cả tin đăng (N)", chip Đang bán / Đã bán + sắp xếp, ô tìm
  Widget _searchHeader(AppLocalizations l) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profAllListings(widget.activeCount + widget.soldCount),
            key: const ValueKey('profile-listing-total'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Chip cuộn ngang được để không tràn trên màn hẹp
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusChip(
                        key: const ValueKey('profile-listing-active'),
                        label: l.profActiveListings(widget.activeCount),
                        selected: !_sold,
                        onTap: () => _showSold(false),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        key: const ValueKey('profile-listing-sold'),
                        label: l.profSoldListings(widget.soldCount),
                        selected: _sold,
                        onTap: () => _showSold(true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (anchor) => OutlinedButton.icon(
                  key: const ValueKey('profile-listing-sort'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xffdddddd)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _pickSort(anchor),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(AppIcons.chevronDown, size: 16),
                  label: Text(_sort.label(l)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('profile-listing-search'),
            controller: _search,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _debounce?.cancel();
              _query = value.trim();
              _load(reset: true);
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: l.profSearchListings,
              prefixIcon: const Icon(AppIcons.search, size: 20),
              suffixIcon: ValueListenableBuilder(
                valueListenable: _search,
                builder: (_, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _search.clear();
                          _onSearch('');
                        },
                      ),
              ),
              filled: true,
              fillColor: const Color(0xfff2f2f2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
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
              child: widget.searchable
                  ? _searchHeader(l)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text(
                        l.sellingListings,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
            if (widget.grid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: AppListingSliverGrid(
                  items: _items,
                  itemBuilder: (_, item) => AppListingCard(
                    item: item,
                    onTap: () => _open(item),
                    onFavoriteTap: () => _favorite(item),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: _items.length,
                itemBuilder: (_, index) {
                  final item = _items[index], listing = item.listing;
                  final date = listing.createdAt;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _open(item),
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
                      ? Text(
                          _query.isEmpty
                              ? l.followShopsListingsEmpty
                              : l.profListingsSearchEmpty,
                        )
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

/// Chip lọc trạng thái tin: chọn = nền đen chữ trắng
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xff222222) : const Color(0xfff0f0f0),
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    ),
  );
}
