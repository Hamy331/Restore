import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../modules/admin/presentation/admin_workspace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../modules/auth/bloc/login/login_bloc.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/auth/views/login/login_view.dart';
import '../../modules/home/views/home_view.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    if (kDebugMode || const bool.fromEnvironment('ENABLE_ADMIN_PREVIEW'))
      GoRoute(
        path: '/admin-preview',
        builder: (context, _) =>
            AdminWorkspace(onExit: () => context.go('/welcome')),
      ),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeView()),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return BlocProvider(
          create: (context) => LoginBloc(AuthRepository()),
          child: const LoginView(),
        );
      },
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) {
        return BlocProvider(
          create: (context) => RegisterBloc(AuthRepository()),
          child: const RegisterView(),
        );
      },
    ),

    GoRoute(path: '/home', builder: (context, state) => const HomeView()),
  ],
);
