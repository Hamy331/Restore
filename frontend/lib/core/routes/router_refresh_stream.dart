import 'dart:async';

import 'package:flutter/foundation.dart';

/// Báo GoRouter chạy lại `redirect` mỗi khi [stream] phát (VD AuthBloc đổi state)
class RouterRefreshStream extends ChangeNotifier {
  RouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
