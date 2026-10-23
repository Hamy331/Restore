import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_state.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/shared/models/geo_point.dart';
import 'package:restore/shared/widgets/app_search_field.dart';
import 'package:restore/modules/home/models/home_listing_item.dart';
import 'package:restore/modules/home/views/home/widgets/home_listing_card.dart';
import 'package:restore/services/device_location_service.dart';
import '../repositories/listings_repository.dart';

class ListingBrowseView extends StatefulWidget {
  const ListingBrowseView({
    this.categoryId = '',
    this.nearby = false,
    this.saved = false,
    this.repository,
    super.key,
  });
  final String categoryId;
  final bool nearby, saved;
  final ListingsRepository? repository;
  @override
  State<ListingBrowseView> createState() => _ListingBrowseViewState();
}

class _ListingBrowseViewState extends State<ListingBrowseView> {
  late final _repository =
      widget.repository ??
      (AppEnvironment.useMockData
          ? MockListingsRepository()
          : ApiListingsRepository());
  final _query = TextEditingController();
  Timer? _debounce;
  List<ListingModel> _items = [];
  final _favorites = <String>{};
  final _favoriteBusy = <String>{};
  GeoPoint? _point;
  bool _loading = false, _more = false, _exchange = false;
  int _page = 0, _version = 0;
  String _error = '';
  @override
  void initState() {
    super.initState();
    if (!widget.nearby) _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _gps() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final point = await DeviceLocationService().getCurrentPosition();
      if (!mounted) return;
      setState(() => _point = point);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không lấy được vị trí. Bật GPS/cấp quyền và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load({bool more = false}) async {
    if (widget.nearby && _point == null) return;
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      if (widget.saved) {
        final items = await _repository.favorites();
        if (mounted && version == _version) {
          setState(() {
            _items = items;
            _more = false;
          });
        }
      } else {
        final result = await _repository.browse(
          page: more ? _page + 1 : 1,
          q: _query.text.trim(),
          categoryId: widget.categoryId,
          exchange: _exchange,
          nearby: _point,
        );
        if (mounted && version == _version) {
          setState(() {
            _items = [if (more) ..._items, ...result.items];
            for (final item in result.items) {
              item.isFavorite
                  ? _favorites.add(item.id)
                  : _favorites.remove(item.id);
            }
            _page = result.page;
            _more = result.hasMore;
          });
        }
      }
    } catch (_) {
      if (mounted && version == _version) {
        setState(() => _error = 'Không tải được danh sách. Thử lại.');
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(ListingModel item) async {
    if (context.read<AuthBloc>().state is! AuthAuthenticated) {
      context.go('/login');
      return;
    }
    if (!_favoriteBusy.add(item.id)) return;
    final favorite = !(widget.saved || _favorites.contains(item.id));
    try {
      await _repository.setFavorite(item.id, favorite);
      if (mounted) {
        setState(() {
          favorite ? _favorites.add(item.id) : _favorites.remove(item.id);
          if (widget.saved) _items.removeWhere((row) => row.id == item.id);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không cập nhật được yêu thích.')),
        );
      }
    } finally {
      _favoriteBusy.remove(item.id);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        widget.saved
            ? 'Tin đã lưu'
            : widget.nearby
            ? 'Tin gần bạn'
            : 'Tìm tin đăng',
      ),
    ),
    body: Column(
      children: [
        if (!widget.saved)
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppSearchField(
              controller: _query,
              hintText: 'Tìm theo tên sản phẩm',
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), _load);
              },
            ),
          ),
        if (!widget.saved)
          FilterChip(
            label: const Text('Có thể trao đổi'),
            selected: _exchange,
            onSelected: (value) {
              _exchange = value;
              _load();
            },
          ),
        if (widget.nearby) ...[
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Bán kính 5 km, ước tính theo tâm khu vực công khai.'),
          ),
          TextButton.icon(
            onPressed: _loading ? null : _gps,
            icon: const Icon(Icons.my_location),
            label: Text(
              _point == null ? 'Dùng vị trí hiện tại' : 'Cập nhật vị trí',
            ),
          ),
        ],
        if (_loading) const LinearProgressIndicator(),
        if (_error.isNotEmpty)
          TextButton(
            onPressed: () => widget.nearby && _point == null ? _gps() : _load(),
            child: Text(_error),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(),
            child: CustomScrollView(
              slivers: [
                if (!_loading &&
                    _items.isEmpty &&
                    _error.isEmpty &&
                    (!widget.nearby || _point != null))
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Chưa có tin phù hợp.')),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = (constraints.crossAxisExtent / 220)
                          .ceil()
                          .clamp(2, 6);
                      final width =
                          (constraints.crossAxisExtent - 12 * (columns - 1)) /
                          columns;
                      return SliverGrid.builder(
                        itemCount: _items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: HomeListingCard.heightFor(width),
                        ),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return HomeListingCard(
                            item: HomeListingItem(
                              listing: item,
                              areaLabel: item.address?.areaLabel ?? '',
                              isFavorite:
                                  widget.saved || _favorites.contains(item.id),
                            ),
                            onTap: () async {
                              await context.push(
                                '/listings/${Uri.encodeComponent(item.id)}',
                              );
                              if (mounted) await _load();
                            },
                            onFavoriteTap: () => _toggleFavorite(item),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_more)
                  SliverToBoxAdapter(
                    child: TextButton(
                      onPressed: _loading ? null : () => _load(more: true),
                      child: const Text('Xem thêm'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
