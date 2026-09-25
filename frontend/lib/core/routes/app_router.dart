import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/auth/bloc/register/register_bloc.dart';
import 'package:restore/modules/auth/views/register/register_view.dart';
import '../../modules/auth/bloc/login/login_bloc.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/auth/views/login/login_view.dart';
import '../../modules/home/views/home_view.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
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
