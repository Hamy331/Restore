import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
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
      child: const HomeMobileView(),
    );
  }
}
