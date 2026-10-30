import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/auth/bloc/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_state.dart';

/// Gửi heartbeat khi người dùng đang mở ứng dụng; backend suy ra online trong 2 phút.
class PresenceReporter extends StatefulWidget {
  const PresenceReporter({required this.child, super.key});
  final Widget child;

  @override
  State<PresenceReporter> createState() => _PresenceReporterState();
}

class _PresenceReporterState extends State<PresenceReporter>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _start() {
    _timer?.cancel();
    unawaited(_pulse());
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(_pulse()),
    );
  }

  Future<void> _pulse() async {
    if (AppEnvironment.useMockData) return;
    try {
      await ApiClient().dio.post<void>('/conversations/heartbeat');
    } catch (_) {
      /* Presence is best-effort while offline. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_authenticated) return;
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (_, state) {
      _authenticated = state is AuthAuthenticated;
      if (_authenticated) {
        _start();
      } else {
        _timer?.cancel();
      }
    },
    child: widget.child,
  );
}
