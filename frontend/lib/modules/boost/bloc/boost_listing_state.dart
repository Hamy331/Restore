import 'package:equatable/equatable.dart';

import '../models/listing_promotion.dart';

enum BoostListingStatus { loading, ready, failure }

class BoostListingState extends Equatable {
  const BoostListingState({
    this.status = BoostListingStatus.loading,
    this.promotion,
    this.selectedPackageId,
    this.busy = false,
    this.changed = false,
  });

  final BoostListingStatus status;
  final ListingPromotion? promotion;

  /// Gói Hot sale đang chọn (mặc định gói ngắn nhất)
  final String? selectedPackageId;

  /// Đang gửi yêu cầu đẩy tin / mua Hot sale: khoá nút, chặn bấm liên tục
  final bool busy;

  /// Đã đẩy hoặc mua Hot sale trong lần mở trang này: trang trước cần tải lại
  final bool changed;

  BoostListingState copyWith({
    BoostListingStatus? status,
    ListingPromotion? promotion,
    String? selectedPackageId,
    bool? busy,
    bool? changed,
  }) => BoostListingState(
    status: status ?? this.status,
    promotion: promotion ?? this.promotion,
    selectedPackageId: selectedPackageId ?? this.selectedPackageId,
    busy: busy ?? this.busy,
    changed: changed ?? this.changed,
  );

  @override
  List<Object?> get props => [
    status,
    promotion,
    selectedPackageId,
    busy,
    changed,
  ];
}

/// Kết quả một lần đẩy tin / mua Hot sale, để trang báo người dùng
sealed class PromotionOutcome {
  const PromotionOutcome();
}

class PromotionDone extends PromotionOutcome {
  const PromotionDone(this.kind);
  final PromotionKind kind;
}

/// Thiếu [missing] xu: mở trang nạp xu
class PromotionNeedsTopUp extends PromotionOutcome {
  const PromotionNeedsTopUp(this.missing);
  final int missing;
}

/// Quảng bá cùng loại đang chạy tới [until]
class PromotionStillRunning extends PromotionOutcome {
  const PromotionStillRunning(this.kind, this.until);
  final PromotionKind kind;
  final DateTime? until;
}

class PromotionFailed extends PromotionOutcome {
  const PromotionFailed([this.message]);
  final String? message;
}
