import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/listing_repository.dart';
import '../../domain/entities/listing_preview.dart';

enum ManagedListingStatus { all, visible, hidden, sold }

extension on ManagedListingStatus {
  String? get apiStatus => switch (this) {
    ManagedListingStatus.all => null,
    ManagedListingStatus.visible => 'AVAILABLE',
    ManagedListingStatus.hidden => 'HIDDEN',
    ManagedListingStatus.sold => 'SOLD',
  };
}

class ManageListingsState {
  const ManageListingsState({
    this.status = ManagedListingStatus.all,
    this.items = const [],
    this.isLoading = false,
    this.busyId,
    this.error = '',
    this.page = 0,
    this.hasMore = false,
  });

  final ManagedListingStatus status;
  final List<ListingPreview> items;
  final bool isLoading;
  final String? busyId;
  final String error;
  final int page;
  final bool hasMore;
}

class ManageListingsCubit extends Cubit<ManageListingsState> {
  ManageListingsCubit({ListingRepository? repository})
    : _repository = repository ?? ListingRepository(),
      super(const ManageListingsState());

  final ListingRepository _repository;
  int _requestVersion = 0;

  Future<void> statusChanged(ManagedListingStatus status) async {
    if (status == state.status) return;
    emit(ManageListingsState(status: status));
    await load();
  }

  Future<void> load({bool more = false}) async {
    if (more && (state.isLoading || !state.hasMore)) return;
    final version = ++_requestVersion;
    final previous = state;
    emit(
      ManageListingsState(
        status: previous.status,
        items: more ? previous.items : const [],
        isLoading: true,
        busyId: previous.busyId,
        page: more ? previous.page : 0,
        hasMore: previous.hasMore,
      ),
    );
    try {
      final page = more ? previous.page + 1 : 1;
      final result = await _repository.mine(
        page: page,
        status: previous.status.apiStatus,
      );
      if (isClosed || version != _requestVersion) return;
      emit(
        ManageListingsState(
          status: previous.status,
          items: [if (more) ...previous.items, ...result.items],
          page: page,
          hasMore: page < result.totalPages,
        ),
      );
    } catch (error) {
      if (isClosed || version != _requestVersion) return;
      emit(
        ManageListingsState(
          status: previous.status,
          items: previous.items,
          page: previous.page,
          hasMore: previous.hasMore,
          error: _message(error),
        ),
      );
    }
  }

  Future<bool> changeStatus(ListingPreview item, String target) async {
    if (state.busyId != null) return false;
    emit(
      ManageListingsState(
        status: state.status,
        items: state.items,
        page: state.page,
        hasMore: state.hasMore,
        busyId: item.id,
      ),
    );
    try {
      await _repository.changeStatus(item.id, target);
      if (isClosed) return false;
      await load();
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          ManageListingsState(
            status: state.status,
            items: state.items,
            page: state.page,
            hasMore: state.hasMore,
            error: _message(error),
          ),
        );
      }
      return false;
    }
  }

  String _message(Object error) {
    if (error is DioException && error.response?.data is Map<String, dynamic>) {
      final message = (error.response!.data as Map<String, dynamic>)['error'];
      if (message is String) return message;
    }
    return 'Không tải hoặc cập nhật được tin. Kiểm tra kết nối rồi thử lại.';
  }
}
