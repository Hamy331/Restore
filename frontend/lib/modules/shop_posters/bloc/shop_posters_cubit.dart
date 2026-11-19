import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';

import '../models/shop_poster.dart';
import '../models/shop_poster_overview.dart';
import '../repositories/shop_poster_repository.dart';

enum ShopPostersStatus { loading, ready, failure }

/// Bộ lọc danh sách poster
enum PosterFilter { all, running, pending, scheduled, rejected, ended }

extension PosterFilterMatch on PosterFilter {
  bool matches(ShopPoster poster) => switch (this) {
    PosterFilter.all => true,
    PosterFilter.running => poster.state == ShopPosterState.running,
    PosterFilter.pending => poster.state == ShopPosterState.pending,
    PosterFilter.scheduled => poster.state == ShopPosterState.scheduled,
    PosterFilter.rejected => poster.state == ShopPosterState.rejected,
    PosterFilter.ended =>
      poster.state == ShopPosterState.ended ||
          poster.state == ShopPosterState.stopped,
  };
}

class ShopPostersState extends Equatable {
  const ShopPostersState({
    this.status = ShopPostersStatus.loading,
    this.overview,
    this.filter = PosterFilter.all,
    this.busyId,
  });

  final ShopPostersStatus status;
  final ShopPosterOverview? overview;
  final PosterFilter filter;

  /// Poster đang được dừng (khóa nút để không bấm hai lần)
  final String? busyId;

  List<ShopPoster> get visible => [
    for (final poster in overview?.posters ?? const <ShopPoster>[])
      if (filter.matches(poster)) poster,
  ];

  int count(PosterFilter filter) =>
      (overview?.posters ?? const <ShopPoster>[]).where(filter.matches).length;

  ShopPostersState copyWith({
    ShopPostersStatus? status,
    ShopPosterOverview? overview,
    PosterFilter? filter,
    String? busyId,
    bool clearBusy = false,
  }) => ShopPostersState(
    status: status ?? this.status,
    overview: overview ?? this.overview,
    filter: filter ?? this.filter,
    busyId: clearBusy ? null : busyId ?? this.busyId,
  );

  @override
  List<Object?> get props => [status, overview, filter, busyId];
}

/// Trang quản lý poster: tải danh sách + hạn mức, lọc, dừng poster
class ShopPostersCubit extends Cubit<ShopPostersState>
    with SafeEmit<ShopPostersState> {
  ShopPostersCubit({required ShopPosterRepository repository})
    : _repository = repository,
      super(const ShopPostersState());

  final ShopPosterRepository _repository;

  ShopPosterRepository get repository => _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ShopPostersStatus.loading));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final overview = await _repository.overview();
      emit(state.copyWith(status: ShopPostersStatus.ready, overview: overview));
    } catch (_) {
      emit(state.copyWith(status: ShopPostersStatus.failure));
    }
  }

  void setFilter(PosterFilter filter) => emit(state.copyWith(filter: filter));

  /// Dừng / hủy poster. Trả về mã lỗi nếu thất bại, null nếu thành công
  Future<String?> stop(String id) async {
    if (state.busyId != null) return null;
    emit(state.copyWith(busyId: id));
    try {
      await _repository.stop(id);
      await refresh();
      return null;
    } on ShopPosterException catch (error) {
      await refresh();
      return error.code;
    } catch (_) {
      return 'NETWORK';
    } finally {
      emit(state.copyWith(clearBusy: true));
    }
  }
}
