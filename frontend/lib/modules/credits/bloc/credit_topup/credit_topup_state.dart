import 'package:equatable/equatable.dart';
import 'package:restore/data/models/credit_package_model.dart';
import 'package:restore/data/models/credit_topup_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';

import '../../models/topup_step.dart';

enum TopupLoadStatus { loading, ready, failure }

/// Kết quả hiển thị ở bước cuối
enum TopupOutcome { success, pending, failed }

class CreditTopupState extends Equatable {
  final TopupStep step;
  final TopupLoadStatus loadStatus;
  final List<CreditPackageModel> packages;
  final String? selectedId;
  final CreditPayMethod method;
  final bool agreed;

  /// Đang gọi API (tạo đơn, giả lập, huỷ, kiểm tra lại)
  final bool busy;
  final CreditTopupModel? order;

  /// Mã lỗi của lần gọi gần nhất (để view báo một lần), '' khi lỗi không rõ
  final String? errorCode;

  const CreditTopupState({
    this.step = TopupStep.choose,
    this.loadStatus = TopupLoadStatus.loading,
    this.packages = const [],
    this.selectedId,
    this.method = CreditPayMethod.vnpay,
    this.agreed = false,
    this.busy = false,
    this.order,
    this.errorCode,
  });

  CreditPackageModel? get selected {
    for (final pack in packages) {
      if (pack.id == selectedId) return pack;
    }
    return null;
  }

  TopupOutcome get outcome => switch (order?.status) {
    TopupStatus.paid => TopupOutcome.success,
    TopupStatus.pending || null => TopupOutcome.pending,
    _ => TopupOutcome.failed,
  };

  CreditTopupState copyWith({
    TopupStep? step,
    TopupLoadStatus? loadStatus,
    List<CreditPackageModel>? packages,
    String? selectedId,
    CreditPayMethod? method,
    bool? agreed,
    bool? busy,
    CreditTopupModel? order,
    bool clearOrder = false,
    String? errorCode,
  }) => CreditTopupState(
    step: step ?? this.step,
    loadStatus: loadStatus ?? this.loadStatus,
    packages: packages ?? this.packages,
    selectedId: selectedId ?? this.selectedId,
    method: method ?? this.method,
    agreed: agreed ?? this.agreed,
    busy: busy ?? this.busy,
    order: clearOrder ? null : (order ?? this.order),
    errorCode: errorCode,
  );

  @override
  List<Object?> get props => [
    step,
    loadStatus,
    packages,
    selectedId,
    method,
    agreed,
    busy,
    order,
    errorCode,
  ];
}
