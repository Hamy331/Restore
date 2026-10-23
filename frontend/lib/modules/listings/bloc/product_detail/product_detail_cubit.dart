import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/listing_model.dart';

import '../../models/product_detail.dart';
import '../../repositories/product_detail_repository.dart';
import 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit({
    required this.listingId,
    required ProductDetailRepository repository,
    ListingModel? preview,
    this.refreshInterval = const Duration(seconds: 15),
  }) : _repository = repository,
       super(ProductDetailState(preview: preview));

  final String listingId;
  final ProductDetailRepository _repository;

  /// Chu kỳ tự tải lại tin khi đang xem, để biết người khác đã mua hoặc
  /// người bán vừa sửa tin
  // TODO: chuyển sang Supabase Realtime khi backend sẵn sàng
  final Duration refreshInterval;

  Timer? _refreshTimer;
  bool _refreshing = false;

  Future<void> load() async {
    emit(state.copyWith(status: ProductDetailStatus.loading));
    try {
      final detail = await _repository.getDetail(listingId);
      emit(
        state.copyWith(
          status: ProductDetailStatus.ready,
          detail: detail,
          initialFavorite: state.initialFavorite ?? detail.isFavorite,
        ),
      );
      resumeLiveUpdates(refreshNow: false);
    } catch (_) {
      emit(state.copyWith(status: ProductDetailStatus.failure));
    }
  }

  /// Tải lại ngầm (không hiện khung chờ), báo thay đổi nếu có.
  /// Lỗi mạng tạm thời thì bỏ qua và giữ dữ liệu đang hiện.
  Future<void> refresh() async {
    if (_refreshing || state.detail == null) return;
    _refreshing = true;
    try {
      _apply(await _repository.getDetail(listingId, countView: false));
    } catch (_) {
      // Lần làm mới sau sẽ thử lại
    } finally {
      _refreshing = false;
    }
  }

  /// Dừng tự làm mới khi ứng dụng chạy nền
  void pauseLiveUpdates() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Bật lại tự làm mới, mặc định tải lại ngay vì có thể đã lỡ thay đổi
  void resumeLiveUpdates({bool refreshNow = true}) {
    if (isClosed || state.detail == null) return;
    pauseLiveUpdates();
    _refreshTimer = Timer.periodic(refreshInterval, (_) => refresh());
    if (refreshNow) refresh();
  }

  /// Ghi dữ liệu mới, trả về thay đổi người mua cần biết (nếu có)
  ProductDetailChange? _apply(ProductDetail latest) {
    final current = state.detail;
    if (isClosed || current == null) return null;
    // Giữ trạng thái "Lưu tin" trên máy vì người xem có thể vừa bấm
    final next = latest.copyWith(isFavorite: current.isFavorite);
    final change = ProductDetailChange.between(current, next);
    emit(
      state.copyWith(
        detail: next,
        lastChange: change,
        changeCount: change == null ? null : state.changeCount + 1,
      ),
    );
    return change;
  }

  /// Lưu / bỏ lưu ngay trên giao diện, hoàn tác nếu gọi API lỗi
  Future<void> toggleFavorite() async {
    final detail = state.detail;
    if (detail == null) return;
    final favorite = !detail.isFavorite;
    emit(state.copyWith(detail: detail.copyWith(isFavorite: favorite)));
    try {
      await _repository.setFavorite(listingId, favorite);
    } catch (_) {
      emit(
        state.copyWith(detail: state.detail!.copyWith(isFavorite: !favorite)),
      );
    }
  }

  /// Mở cuộc trò chuyện với người bán, trả về id, null khi lỗi
  Future<String?> openConversation() async {
    if (state.isSubmitting) return null;
    emit(state.copyWith(isSubmitting: true));
    try {
      return await _repository.openConversation(listingId);
    } catch (_) {
      return null;
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }

  Future<ProductActionResult> sendOffer(int amount) =>
      _submit(() => _repository.sendOffer(listingId, amount));

  Future<ProductActionResult> requestPurchase({String? note}) =>
      _submit(() => _repository.requestPurchase(listingId, note: note));

  /// Kiểm tra lại tin ngay trước khi gửi: nếu người khác vừa mua hoặc người
  /// bán vừa đổi giá thì không gửi để người mua xem lại
  Future<ProductActionResult> _submit(Future<String> Function() action) async {
    if (state.isSubmitting) return const ProductActionFailed();
    emit(state.copyWith(isSubmitting: true));
    try {
      final change = _apply(
        await _repository.getDetail(listingId, countView: false),
      );
      if (change?.kind == ProductDetailChangeKind.price ||
          !(state.detail?.isAvailable ?? false)) {
        return const ProductActionOutdated();
      }
      return ProductActionSent(await action());
    } catch (_) {
      return const ProductActionFailed();
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }

  @override
  Future<void> close() {
    pauseLiveUpdates();
    return super.close();
  }
}
