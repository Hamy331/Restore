import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/auth/bloc/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_state.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';

import '../../bloc/home_cubit.dart';
import '../../repositories/home_repository.dart';
import 'home_mobile_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        homeRepository: AppEnvironment.useMockData
            ? MockHomeRepository()
            : ApiHomeRepository(),
        categoryRepository: AppEnvironment.useMockData
            ? MockCategoryRepository()
            : ApiCategoryRepository(),
      )..load(),
      // Trang chủ được giữ trong thanh điều hướng nên không tạo lại khi
      // đăng nhập / đăng xuất: tải lại để tin gợi ý và tin đã lưu đúng người
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            _userId(previous) != _userId(current),
        listener: (context, _) =>
            context.read<HomeCubit>().load(showLoading: false),
        child: const HomeMobileView(),
      ),
    );
  }

  static String? _userId(AuthState state) =>
      state is AuthAuthenticated ? state.user.id : null;
}
