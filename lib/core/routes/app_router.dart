import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../modules/auth/views/login/login_view.dart';
import '../../modules/auth/bloc/login/login_bloc.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return BlocProvider(
          create: (context) => LoginBloc(),
          child: const LoginView(),
        );
      },
    ),
  ],
);
