import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';

import '../../listings/repositories/listings_repository.dart';
import '../models/listing_promotion.dart';
import '../models/promotion_hub.dart';
import '../repositories/promotion_repository.dart';
import 'boost_listing_state.dart';

enum PromotionHubStatus { loading, ready, failure }

/// Bộ lọc trang Boost
enum PromotionHubFilter { all, running, expiring, idle }

class PromotionHubState extends Equatable {
  const PromotionHubState({
    this.status = PromotionHubStatus.loading,
    this.hub,
    this.filter = PromotionHubFilter.all,
    this.busyId,
  });

  final PromotionHubStatus status;
  final PromotionHub? hub;
  final PromotionHubFilter filter;

  /// Tin đang được đẩy / gia hạn: khoá nút của tin đó
  final String? busyId;

  /// Các tin theo [filter] tại thời điểm [now]
  List<PromotionHubItem> itemsAt(DateTime now, [PromotionHubFilter? of]) {
    final items = hub?.items ?? const <PromotionHubItem>[];
    return switch (of ?? filter) {
      PromotionHubFilter.all => items,
      PromotionHubFilter.running =>
        items.where((i) => i.isPromotedAt(now)).toList(),
      PromotionHubFilter.expiring =>
        items.where((i) => i.isExpiringAt(now)).toList(),
      PromotionHubFilter.idle =>
        items.where((i) => !i.isPromotedAt(now)).toList(),
    };
  }

  PromotionHubState copyWith({
    PromotionHubStatus? status,
    PromotionHub? hub,
    PromotionHubFilter? filter,
    String? Function()? busyId,
  }) => PromotionHubState(
    status: status ?? this.status,
    hub: hub ?? this.hub,
    filter: filter ?? this.filter,
    busyId: busyId == null ? this.busyId : busyId(),
  );

  @override
  List<Object?> get props => [status, hub, filter, busyId];
}

/// Trang Boost: các tin đang hiển thị, lọc theo đang quảng bá / sắp hết hạn /
/// chưa quảng bá, đẩy tin và gia hạn ngay trên danh sách. Mỗi lần chỉ chạy
/// một yêu cầu.
class PromotionHubCubit extends Cubit<PromotionHubState>
    with SafeEmit<PromotionHubState> {
  PromotionHubCubit({required PromotionRepository repository})
    : _repository = repository,
      super(const PromotionHubState());

  final PromotionRepository _repository;
  PromotionRepository get repository => _repository;

  Future<void> load() async {
    emit(state.copyWith(status: PromotionHubStatus.loading));
    await _reload(onError: PromotionHubStatus.failure);
  }

  Future<void> refresh() => _reload();

  void setFilter(PromotionHubFilter filter) =>
      emit(state.copyWith(filter: filter));

  /// Null khi đang có yêu cầu khác chạy
  Future<PromotionOutcome?> boost(PromotionHubItem item) async {
    if (state.busyId != null) return null;
    emit(state.copyWith(busyId: () => item.id));
    PromotionOutcome outcome;
    try {
      await _repository.boost(item.id);
      outcome = const PromotionDone(PromotionKind.bump);
    } on ListingBoostException catch (error) {
      outcome = switch (error.code) {
        ListingBoostException.notEnoughCredits => PromotionNeedsTopUp(
          (error.details['missing'] as num?)?.toInt() ?? 1,
        ),
        ListingBoostException.tooSoon => PromotionStillRunning(
          PromotionKind.bump,
          DateTime.tryParse('${error.details['availableAt']}')?.toLocal(),
        ),
        _ => PromotionFailed(error.message),
      };
    } catch (_) {
      outcome = const PromotionFailed();
    }
    await _reload();
    emit(state.copyWith(busyId: () => null));
    return outcome;
  }

  /// Gia hạn [item] thêm [days] ngày; lỗi từ backend ném lại cho trang báo
  Future<void> extend(PromotionHubItem item, int days) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: () => item.id));
    try {
      await _repository.extend(item.id, days);
    } finally {
      await _reload();
      emit(state.copyWith(busyId: () => null));
    }
  }

  Future<void> _reload({PromotionHubStatus? onError}) async {
    try {
      final hub = await _repository.hub();
      emit(state.copyWith(status: PromotionHubStatus.ready, hub: hub));
    } catch (_) {
      if (onError != null) emit(state.copyWith(status: onError));
    }
  }
}
