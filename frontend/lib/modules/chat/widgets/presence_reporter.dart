import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_state.dart';

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
  bool _inFlight = false;
  bool _active = true;
  String? _userId;
  DateTime? _lastAttempt;
  Duration _interval = const Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _active =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final state = context.read<AuthBloc>().state;
    _authenticated = state is AuthAuthenticated;
    if (state is AuthAuthenticated) _userId = state.user.id;
    if (_authenticated && _active) _start();
  }

  void _start() {
    _timer?.cancel();
    if (!_authenticated || !_active || AppEnvironment.useMockData) return;
    final elapsed = _lastAttempt == null
        ? _interval
        : DateTime.now().difference(_lastAttempt!);
    final delay = _interval - elapsed;
    _timer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(_pulse()),
    );
  }

  Future<void> _pulse() async {
    if (!mounted ||
        !_authenticated ||
        !_active ||
        _inFlight ||
        AppEnvironment.useMockData) {
      return;
    }
    _inFlight = true;
    final userId = _userId;
    _lastAttempt = DateTime.now();
    try {
      await ApiClient().dio.post<void>('/conversations/heartbeat');
      if (_userId == userId) _interval = const Duration(seconds: 60);
    } catch (_) {
      if (_userId == userId) {
        _interval = Duration(seconds: (_interval.inSeconds * 2).clamp(60, 300));
      }
    } finally {
      _inFlight = false;
      if (mounted) _start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
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
      final nextId = state is AuthAuthenticated ? state.user.id : null;
      if (nextId == _userId) return;
      _userId = nextId;
      _lastAttempt = null;
      _interval = const Duration(seconds: 60);
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
