import 'package:flutter_bloc/flutter_bloc.dart';

/// Bỏ qua state phát ra sau khi bloc / cubit đã đóng (VD rời trang khi
/// request còn đang chạy), thay vì ném `StateError: Cannot emit new states
/// after calling close`.
mixin SafeEmit<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (!isClosed) super.emit(state);
  }
}
