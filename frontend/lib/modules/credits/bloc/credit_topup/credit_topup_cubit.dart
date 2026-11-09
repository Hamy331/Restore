import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/credit_topup_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';

import '../../models/topup_step.dart';
import '../../repositories/credit_repository.dart';
import 'credit_topup_state.dart';

/// Luồng nạp xu trên một trang: chọn gói → xác nhận → trả tiền → kết quả.
///
/// App không tự cộng xu: chỉ tạo đơn rồi hỏi lại trạng thái. Backend đổi đơn
/// sang PAID khi cổng xác nhận (hoặc khi bấm giả lập ở chế độ thử).
class CreditTopupCubit extends Cubit<CreditTopupState> {
  CreditTopupCubit({
    required CreditRepository repository,
    this.pollInterval = const Duration(seconds: 5),
  }) : _repository = repository,
       super(const CreditTopupState());

  final CreditRepository _repository;

  /// Khoảng hỏi lại trạng thái khi đang chờ tiền chuyển khoản về
  final Duration pollInterval;
  Timer? _poll;

  /// Tải gói; [preselectId] chọn sẵn một gói (VD gói nhỏ nhất đủ dùng),
  /// không có thì chọn gói phổ biến
  Future<void> load({String? preselectId}) async {
    emit(state.copyWith(loadStatus: TopupLoadStatus.loading));
    try {
      final packages = await _repository.getPackages();
      if (isClosed) return;
      final ids = packages.map((p) => p.id).toSet();
      final popular = packages.where((p) => p.popular).map((p) => p.id);
      emit(
        state.copyWith(
          loadStatus: TopupLoadStatus.ready,
          packages: packages,
          selectedId: ids.contains(preselectId)
              ? preselectId
              : (popular.isNotEmpty
                    ? popular.first
                    : (packages.isEmpty ? null : packages.first.id)),
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(loadStatus: TopupLoadStatus.failure));
    }
  }

  void selectPackage(String id) => emit(state.copyWith(selectedId: id));

  void selectMethod(CreditPayMethod method) =>
      emit(state.copyWith(method: method));

  void toggleAgreed() => emit(state.copyWith(agreed: !state.agreed));

  void next() {
    if (state.step == TopupStep.choose && state.selected != null) {
      emit(state.copyWith(step: TopupStep.confirm));
    }
  }

  /// Lùi một bước. Trả false khi đang ở bước đầu hoặc kết quả (để trang đóng).
  /// Đang trả tiền thì lùi về xác nhận và bỏ đơn (đơn tự hết hạn sau 15 phút).
  bool back() {
    switch (state.step) {
      case TopupStep.confirm:
        emit(state.copyWith(step: TopupStep.choose));
        return true;
      case TopupStep.pay:
        _stopPolling();
        emit(state.copyWith(step: TopupStep.confirm, clearOrder: true));
        return true;
      case TopupStep.choose:
      case TopupStep.result:
        return false;
    }
  }

  /// Tạo đơn nạp rồi sang bước trả tiền
  Future<void> pay() async {
    final pack = state.selected;
    if (pack == null || !state.agreed || state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final order = await _repository.createTopup(pack.id, state.method);
      if (isClosed) return;
      emit(state.copyWith(busy: false, order: order, step: TopupStep.pay));
      if (order.method == CreditPayMethod.vietQr) _startPolling();
    } on CreditException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, errorCode: error.code ?? ''));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, errorCode: ''));
    }
  }

  /// Cổng thử: giả lập cổng trả kết quả
  Future<void> simulate({required bool success}) =>
      _act((id) => _repository.simulate(id, success: success));

  /// Huỷ đơn đang chờ trả
  Future<void> cancel() => _act((id) async {
    await _repository.cancelTopup(id);
    return _repository.getTopup(id);
  });

  /// Hỏi lại trạng thái đơn (nút "Kiểm tra lại" hoặc người dùng báo đã chuyển)
  Future<void> refresh() => _act(_repository.getTopup);

  /// Gọi API với đơn hiện tại rồi sang bước kết quả
  Future<void> _act(Future<CreditTopupModel> Function(String id) call) async {
    final order = state.order;
    if (order == null || state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final updated = await call(order.id);
      if (isClosed) return;
      _stopPolling();
      emit(state.copyWith(busy: false, order: updated, step: TopupStep.result));
    } on CreditException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, errorCode: error.code ?? ''));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, errorCode: ''));
    }
  }

  /// Thử lại sau khi thất bại: về bước xác nhận với cùng gói và cách trả
  void retry() {
    _stopPolling();
    emit(state.copyWith(step: TopupStep.confirm, clearOrder: true));
  }

  void _startPolling() {
    _stopPolling();
    _poll = Timer.periodic(pollInterval, (_) => _pollOnce());
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  /// Hỏi lặng lẽ; đơn hết chờ (đã trả, huỷ, hết hạn) thì sang kết quả
  Future<void> _pollOnce() async {
    final order = state.order;
    if (order == null || state.busy || state.step != TopupStep.pay) {
      _stopPolling();
      return;
    }
    try {
      final updated = await _repository.getTopup(order.id);
      if (isClosed || state.order?.id != updated.id) return;
      if (updated.status != TopupStatus.pending) {
        _stopPolling();
        emit(state.copyWith(order: updated, step: TopupStep.result));
      }
    } catch (_) {
      // Lỗi mạng tạm thời: lần sau hỏi lại
    }
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
