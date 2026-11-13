import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';

import '../models/seller_insights.dart';
import '../repositories/insights_repository.dart';

enum InsightsStatus { loading, ready, failure }

class InsightsState extends Equatable {
  const InsightsState({
    this.status = InsightsStatus.loading,
    this.days = 7,
    this.insights,
    this.selectedDay,
  });

  final InsightsStatus status;
  final int days;
  final SellerInsights? insights;

  /// Cột đang chạm trên biểu đồ (vị trí trong [SellerInsights.daily])
  final int? selectedDay;

  InsightsState copyWith({
    InsightsStatus? status,
    int? days,
    SellerInsights? insights,
    int? Function()? selectedDay,
  }) => InsightsState(
    status: status ?? this.status,
    days: days ?? this.days,
    insights: insights ?? this.insights,
    selectedDay: selectedDay == null ? this.selectedDay : selectedDay(),
  );

  @override
  List<Object?> get props => [status, days, insights, selectedDay];
}

/// Trang Thống kê: đổi 7 / 30 ngày, kéo để làm mới, chạm cột biểu đồ
class InsightsCubit extends Cubit<InsightsState> with SafeEmit<InsightsState> {
  InsightsCubit({required InsightsRepository repository})
    : _repository = repository,
      super(const InsightsState());

  final InsightsRepository _repository;

  /// Tăng mỗi lần tải để bỏ kết quả cũ về muộn (đổi khoảng liên tục)
  int _request = 0;

  Future<void> load() => _load(showLoading: true);

  Future<void> refresh() => _load();

  Future<void> setDays(int days) async {
    if (days == state.days) return;
    emit(state.copyWith(days: days, selectedDay: () => null));
    await _load(showLoading: true);
  }

  /// Chạm lại cột đang chọn thì bỏ chọn
  void selectDay(int? index) => emit(
    state.copyWith(
      selectedDay: () => index == state.selectedDay ? null : index,
    ),
  );

  Future<void> _load({bool showLoading = false}) async {
    final request = ++_request;
    if (showLoading) emit(state.copyWith(status: InsightsStatus.loading));
    try {
      final insights = await _repository.load(state.days);
      if (request != _request) return;
      emit(
        state.copyWith(
          status: InsightsStatus.ready,
          insights: insights,
          selectedDay: () => null,
        ),
      );
    } catch (_) {
      if (request != _request) return;
      // Đã có số liệu thì giữ lại, chỉ báo lỗi khi chưa có gì để hiện
      if (state.insights == null || showLoading) {
        emit(state.copyWith(status: InsightsStatus.failure));
      }
    }
  }
}
