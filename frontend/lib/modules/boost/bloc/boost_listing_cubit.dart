import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';

import '../../listings/repositories/listings_repository.dart';
import '../models/listing_promotion.dart';
import '../repositories/promotion_repository.dart';
import 'boost_listing_state.dart';

export 'boost_listing_state.dart';

/// Trang quảng bá một tin: tải giá và trạng thái, đẩy tin 24 giờ, mua Hot sale
/// bằng xu. Mỗi lần chỉ chạy một yêu cầu (bấm liên tục thì bỏ qua).
class BoostListingCubit extends Cubit<BoostListingState>
    with SafeEmit<BoostListingState> {
  BoostListingCubit({
    required this.listingId,
    required PromotionRepository repository,
  }) : _repository = repository,
       super(const BoostListingState());

  final String listingId;
  final PromotionRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: BoostListingStatus.loading));
    await _reload(onError: BoostListingStatus.failure);
  }

  /// Tải lại sau khi nạp xu hoặc kéo để làm mới, giữ dữ liệu cũ khi lỗi
  Future<void> refresh() => _reload();

  void selectPackage(String packageId) =>
      emit(state.copyWith(selectedPackageId: packageId));

  FeatureOption? get selectedOption {
    final options = state.promotion?.featureOptions ?? const [];
    for (final option in options) {
      if (option.packageId == state.selectedPackageId) return option;
    }
    return options.isEmpty ? null : options.first;
  }

  /// Null khi đang có yêu cầu khác chạy
  Future<PromotionOutcome?> boost() => _run(PromotionKind.bump, () async {
    await _repository.boost(listingId);
  });

  Future<PromotionOutcome?> feature() {
    final option = selectedOption;
    if (option == null) return Future.value(const PromotionFailed());
    return _run(PromotionKind.featured, () async {
      await _repository.feature(listingId, option.packageId);
    });
  }

  Future<PromotionOutcome?> _run(
    PromotionKind kind,
    Future<void> Function() action,
  ) async {
    if (state.busy) return null;
    emit(state.copyWith(busy: true));
    PromotionOutcome outcome;
    try {
      await action();
      emit(state.copyWith(changed: true));
      outcome = PromotionDone(kind);
    } on ListingBoostException catch (error) {
      outcome = switch (error.code) {
        ListingBoostException.notEnoughCredits => PromotionNeedsTopUp(
          (error.details['missing'] as num?)?.toInt() ?? 1,
        ),
        ListingBoostException.tooSoon ||
        ListingBoostException.featureActive => PromotionStillRunning(
          kind,
          DateTime.tryParse('${error.details['availableAt']}')?.toLocal(),
        ),
        _ => PromotionFailed(error.message),
      };
    } catch (_) {
      outcome = const PromotionFailed();
    }
    await _reload();
    emit(state.copyWith(busy: false));
    return outcome;
  }

  Future<void> _reload({BoostListingStatus? onError}) async {
    try {
      final promotion = await _repository.overview(listingId);
      final selected = state.selectedPackageId;
      final keep = promotion.featureOptions.any((o) => o.packageId == selected);
      emit(
        state.copyWith(
          status: BoostListingStatus.ready,
          promotion: promotion,
          selectedPackageId: keep
              ? selected
              : (promotion.featureOptions.isEmpty
                    ? null
                    : promotion.featureOptions.first.packageId),
        ),
      );
    } catch (_) {
      if (onError != null) emit(state.copyWith(status: onError));
    }
  }
}
