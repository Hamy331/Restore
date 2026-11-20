import 'package:restore/shared/models/geo_point.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';

import '../models/home_listing_filter.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import '../repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required HomeRepository homeRepository,
    required CategoryRepository categoryRepository,
  }) : _homeRepository = homeRepository,
       _categoryRepository = categoryRepository,
       super(const HomeState());

  final HomeRepository _homeRepository;
  final CategoryRepository _categoryRepository;

  GeoPoint? _origin;
  int _feedRequest = 0;
  int _homeRequest = 0;

  @override
  void emit(HomeState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  /// Người dùng không lấy ở đây mà đọc từ AuthBloc; đăng nhập / đăng xuất thì
  /// HomeView gọi lại để tải lại trạng thái lưu tin và tin gợi ý.
  ///
  /// [showLoading] false khi kéo để làm mới: giữ nội dung cũ tới khi có dữ liệu
  Future<void> load({bool showLoading = true}) async {
    final request = ++_homeRequest;
    if (showLoading) emit(state.copyWith(status: HomeStatus.loading));
    try {
      final (banners, categories, recommended, _) = await (
        _homeRepository.getBanners(),
        _categoryRepository.getCategories(),
        _homeRepository.getRecommended(),
        _reloadFeed(state.filter),
      ).wait;
      if (request != _homeRequest) return;
      emit(
        state.copyWith(
          status: HomeStatus.ready,
          banners: banners,
          categories: categories,
          recommended: recommended,
        ),
      );
    } catch (_) {
      if (request == _homeRequest &&
          (showLoading || state.status != HomeStatus.ready)) {
        emit(state.copyWith(status: HomeStatus.failure));
      }
    }
  }

  Future<void> selectFeed(HomeListingFilter filter, GeoPoint? origin) async {
    if (filter == state.filter &&
        (filter != HomeListingFilter.nearby || origin == _origin)) {
      return;
    }
    _origin = origin;
    await _reloadFeed(filter);
  }

  Future<void> _reloadFeed(HomeListingFilter filter) async {
    ++_feedRequest;
    emit(
      state.copyWith(
        filter: filter,
        latest: [],
        latestPage: 0,
        isLoadingMore: false,
        feedFailed: false,
        hasMoreLatest: filter != HomeListingFilter.nearby || _origin != null,
      ),
    );
    await loadMore();
  }

  Future<void> loadMore({bool retry = false}) async {
    if (!state.hasMoreLatest ||
        state.isLoadingMore ||
        (state.feedFailed && !retry)) {
      return;
    }
    final request = _feedRequest;
    emit(state.copyWith(isLoadingMore: true, feedFailed: false));
    try {
      final result = await _homeRepository.getLatest(
        state.filter,
        origin: state.filter == HomeListingFilter.nearby ? _origin : null,
        page: state.latestPage + 1,
      );
      if (request != _feedRequest) return;
      emit(
        state.copyWith(
          latest: [...state.latest, ...result.items],
          latestPage: result.page,
          hasMoreLatest: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (request == _feedRequest) {
        emit(state.copyWith(isLoadingMore: false, feedFailed: true));
      }
    }
  }

  /// Đổi trạng thái lưu tin ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> toggleFavorite(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = !item.isFavorite;
    _setFavorite(id, favorite);
    try {
      await _homeRepository.setFavorite(id, favorite);
    } catch (_) {
      _setFavorite(id, !favorite);
    }
  }

  /// Cập nhật thẻ tin sau khi người dùng lưu / bỏ lưu ở trang chi tiết
  /// (trang chi tiết đã gọi API nên chỉ đổi trạng thái hiển thị)
  void syncFavorite(String listingId, bool favorite) =>
      _setFavorite(listingId, favorite);

  void _setFavorite(String id, bool favorite) {
    List<ListingCardItem> update(List<ListingCardItem> items) => [
      for (final item in items)
        item.listing.id == id ? item.copyWith(isFavorite: favorite) : item,
    ];
    emit(
      state.copyWith(
        recommended: update(state.recommended),
        latest: update(state.latest),
      ),
    );
  }
}
