import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/search_cubit.dart';
import '../../repositories/search_repository.dart';
import 'search_mobile_view.dart';

/// Route `/search?q=`: gõ từ khoá, gợi ý tìm nhanh và lịch sử tìm kiếm.
/// [initialQuery] là từ khoá điền sẵn (VD quay lại từ trang kết quả).
class SearchView extends StatelessWidget {
  final String initialQuery;

  const SearchView({super.key, this.initialQuery = ''});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(
        searchRepository: AppEnvironment.useMockData
            ? MockSearchRepository()
            : ApiSearchRepository(),
        query: initialQuery,
      )..start(),
      child: TResponsiveLayout(
        mobile: SearchMobileView(initialQuery: initialQuery),
      ),
    );
  }
}
