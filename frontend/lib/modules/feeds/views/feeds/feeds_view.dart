import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'feeds_mobile_view.dart';
import '../../repositories/feeds_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/feeds/feeds_cubit.dart';

class FeedsView extends StatelessWidget {
  const FeedsView({super.key, this.repository});
  final FeedsRepository? repository;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => FeedsCubit(repository: repository)
      ..load()
      ..loadMe(),
    child: const TResponsiveLayout(mobile: FeedsMobileView()),
  );
}
