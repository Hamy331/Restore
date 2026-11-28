import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/chat_realtime.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_state.dart';

class ChatConnection extends StatefulWidget {
  const ChatConnection({required this.child, super.key});
  final Widget child;

  @override
  State<ChatConnection> createState() => _ChatConnectionState();
}

class _ChatConnectionState extends State<ChatConnection>
    with WidgetsBindingObserver {
  String? _user;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final auth = context.read<AuthBloc>().state;
    _user = auth is AuthAuthenticated ? auth.user.id : null;
    _update();
  }

  void _update() => ChatRealtime.instance.session(
    _active && !AppEnvironment.useMockData ? _user : null,
  );
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _update();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatRealtime.instance.session(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (_, state) {
      _user = state is AuthAuthenticated ? state.user.id : null;
      _update();
    },
    child: widget.child,
  );
}
