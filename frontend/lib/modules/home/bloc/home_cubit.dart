import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';

import '../models/home_listing_filter.dart';
import '../models/home_listing_item.dart';
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

  /// "Tin đăng mới" luôn xếp theo mới nhất; lọc gần bạn/trao đổi nằm ở
  /// trang riêng
  static const _latestFilter = HomeListingFilter.newest;

  @override
  void emit(HomeState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  /// [showLoading] false khi kéo để làm mới: giữ nội dung cũ tới khi có dữ liệu
  Future<void> load({bool showLoading = true}) async {
    if (showLoading) emit(state.copyWith(status: HomeStatus.loading));
    try {
      // Gọi song song, chờ đủ cả trang rồi mới hiển thị
      final (user, areaName, banners, categories, recommended, latest) = await (
        _homeRepository.getCurrentUser(),
        _homeRepository.getAreaName(),
        _homeRepository.getBanners(),
        _categoryRepository.getCategories(),
        _homeRepository.getRecommended(),
        _homeRepository.getLatest(_latestFilter),
      ).wait;
      emit(
        state.copyWith(
          status: HomeStatus.ready,
          user: user,
          areaName: areaName,
          banners: banners,
          categories: categories,
          recommended: recommended,
          latest: latest.items,
          latestPage: latest.page,
          hasMoreLatest: latest.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // Làm mới thất bại thì giữ nội dung đang có
      if (showLoading || state.status != HomeStatus.ready) {
        emit(state.copyWith(status: HomeStatus.failure));
      }
    }
  }

  /// Tải trang tiếp theo; tự bỏ qua khi đang tải hoặc đã hết
  Future<void> loadMore() async {
    if (state.status != HomeStatus.ready ||
        !state.hasMoreLatest ||
        state.isLoadingMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _homeRepository.getLatest(
        _latestFilter,
        page: state.latestPage + 1,
      );
      emit(
        state.copyWith(
          latest: [...state.latest, ...result.items],
          latestPage: result.page,
          hasMoreLatest: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Đổi trạng thái lưu tin ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> toggleFavorite(HomeListingItem item) async {
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
    List<HomeListingItem> update(List<HomeListingItem> items) => [
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
