import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_state.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';

import '../../bloc/home_cubit.dart';
import '../../repositories/home_repository.dart';
import 'home_mobile_view.dart';
import 'home_desktop_view.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import '../../models/home_listing_filter.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_state.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, this.homeRepository, this.categoryRepository});
  final HomeRepository? homeRepository;
  final CategoryRepository? categoryRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        homeRepository:
            homeRepository ??
            (AppEnvironment.useMockData
                ? MockHomeRepository()
                : ApiHomeRepository()),
        categoryRepository:
            categoryRepository ??
            (AppEnvironment.useMockData
                ? MockCategoryRepository()
                : ApiCategoryRepository()),
      )..load(),
      // Trang chủ được giữ trong thanh điều hướng nên không tạo lại khi
      // đăng nhập / đăng xuất: tải lại để tin gợi ý và tin đã lưu đúng người
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            _userId(previous) != _userId(current),
        listener: (context, _) =>
            context.read<HomeCubit>().load(showLoading: false),
        child: BlocListener<UserAreaCubit, UserAreaState>(
          listener: (context, area) {
            final home = context.read<HomeCubit>();
            if (home.state.filter == HomeListingFilter.nearby) {
              home.selectFeed(HomeListingFilter.nearby, area.origin);
            }
          },
          child: const TResponsiveLayout(
            mobile: HomeMobileView(),
            desktop: HomeDesktopView(),
          ),
        ),
      ),
    );
  }

  static String? _userId(AuthState state) =>
      state is AuthAuthenticated ? state.user.id : null;
}
