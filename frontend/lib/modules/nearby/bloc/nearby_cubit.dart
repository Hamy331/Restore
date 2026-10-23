import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../models/nearby_origin.dart';
import '../repositories/nearby_repository.dart';
import 'nearby_state.dart';

class NearbyCubit extends Cubit<NearbyState> {
  NearbyCubit({
    required NearbyRepository nearbyRepository,
    required LocationRepository locationRepository,
    required DeviceLocationService locationService,
  }) : _nearbyRepository = nearbyRepository,
       _locationRepository = locationRepository,
       _locationService = locationService,
       super(const NearbyState());

  final NearbyRepository _nearbyRepository;
  final LocationRepository _locationRepository;
  final DeviceLocationService _locationService;

  /// Tăng mỗi lần tải lại trang đầu để bỏ kết quả của lần tải cũ về muộn
  /// (VD bấm đổi bán kính liên tục)
  int _requestId = 0;

  @override
  void emit(NearbyState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  /// Mở trang: lấy vị trí rồi tải tin quanh đó
  Future<void> start() async {
    emit(state.copyWith(status: NearbyStatus.locating));
    try {
      final origin = await _locate();
      emit(state.copyWith(origin: origin));
      await _reload();
    } catch (_) {
      emit(state.copyWith(status: NearbyStatus.failure));
    }
  }

  /// Lấy lại vị trí GPS (VD sau khi người dùng vừa bật định vị)
  Future<void> relocate() async {
    if (state.isRelocating) return;
    if (state.origin == null) return start();
    emit(state.copyWith(isRelocating: true));
    try {
      final origin = await _locate();
      emit(state.copyWith(origin: origin, isRelocating: false));
      await _reload();
    } catch (_) {
      emit(state.copyWith(isRelocating: false));
    }
  }

  /// Xem tin quanh một khu vực người dùng tự chọn (thay cho vị trí GPS)
  Future<void> setArea(AreaOption area) async {
    emit(
      state.copyWith(
        origin: NearbyOrigin(point: area.center, label: area.label),
      ),
    );
    await _reload();
  }

  /// Kéo để làm mới: giữ danh sách cũ tới khi có dữ liệu mới
  Future<void> refresh() => _reload(showLoading: false);

  Future<void> retry() => state.origin == null ? start() : _reload();

  void setRadius(double km) {
    if (km == state.filter.radiusKm) return;
    _applyFilter(state.filter.copyWith(radiusKm: km));
  }

  void setSort(ListingSort sort) {
    if (sort == state.filter.sort) return;
    _applyFilter(state.filter.copyWith(sort: sort));
  }

  void toggleDeal(ListingDealType type) =>
      _applyFilter(state.filter.toggleDeal(type));

  /// Nhận bộ lọc từ sheet Bộ lọc đầy đủ
  void applyFilter(ListingFilter filter) {
    if (filter == state.filter) return;
    _applyFilter(filter);
  }

  /// Xoá mọi tiêu chí về mặc định của trang, giữ cách sắp xếp
  void clearFilters() =>
      applyFilter(state.filter.resetTo(NearbyState.defaultFilter));

  Future<bool> openLocationSettings() => _locationService.openAppSettings();

  /// Tải trang tiếp theo; tự bỏ qua khi đang tải hoặc đã hết
  Future<void> loadMore() async {
    final origin = state.origin;
    if (origin == null ||
        state.status != NearbyStatus.ready ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _nearbyRepository.getNearby(
        origin.point,
        state.filter,
        page: state.page + 1,
      );
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          items: [...state.items, ...result.items],
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId == _requestId) emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Đổi trạng thái lưu tin ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> toggleFavorite(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = !item.isFavorite;
    syncFavorite(id, favorite);
    try {
      await _nearbyRepository.setFavorite(id, favorite);
    } catch (_) {
      syncFavorite(id, !favorite);
    }
  }

  /// Cập nhật thẻ tin sau khi lưu / bỏ lưu ở trang chi tiết
  void syncFavorite(String listingId, bool favorite) => emit(
    state.copyWith(
      items: [
        for (final item in state.items)
          item.listing.id == listingId
              ? item.copyWith(isFavorite: favorite)
              : item,
      ],
    ),
  );

  void _applyFilter(ListingFilter filter) {
    emit(state.copyWith(filter: filter));
    _reload();
  }

  /// Ưu tiên GPS của máy; không được thì dùng khu vực mặc định của tài khoản
  /// và ghi lại lý do để trang gợi ý bật định vị
  Future<NearbyOrigin> _locate() async {
    try {
      final point = await _locationService.getCurrentPosition();
      String? label;
      try {
        label = (await _locationRepository.reverseGeocode(point))?.areaLabel;
      } catch (_) {
        // Không đổi được ra tên khu vực thì vẫn dùng toạ độ
      }
      return NearbyOrigin(point: point, label: label, isFromDevice: true);
    } on DeviceLocationException catch (error) {
      final fallback = await _nearbyRepository.getDefaultOrigin();
      return fallback.withError(error.error);
    } catch (_) {
      final fallback = await _nearbyRepository.getDefaultOrigin();
      return fallback.withError(DeviceLocationError.unavailable);
    }
  }

  /// Tải lại trang đầu theo vị trí và bộ lọc hiện tại.
  /// [showLoading] false khi kéo để làm mới.
  Future<void> _reload({bool showLoading = true}) async {
    final origin = state.origin;
    if (origin == null) return;
    final requestId = ++_requestId;
    if (showLoading) {
      emit(state.copyWith(status: NearbyStatus.loading, isLoadingMore: false));
    }
    try {
      final result = await _nearbyRepository.getNearby(
        origin.point,
        state.filter,
      );
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          status: NearbyStatus.ready,
          items: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      // Làm mới thất bại thì giữ nội dung đang có
      if (showLoading || state.status != NearbyStatus.ready) {
        emit(state.copyWith(status: NearbyStatus.failure));
      }
    }
  }
}
