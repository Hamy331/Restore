import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/search_results_cubit.dart';
import '../../repositories/search_repository.dart';
import 'search_results_mobile_view.dart';

/// Route `/search/results?q=`: tin khớp từ khoá [query].
/// [fromSearch] true khi mở từ trang tìm kiếm, bấm ô tìm kiếm sẽ quay lại
/// trang đó thay vì mở trang mới.
class SearchResultsView extends StatelessWidget {
  final String query;
  final bool fromSearch;

  const SearchResultsView({
    super.key,
    required this.query,
    this.fromSearch = false,
  });

  static const String path = '/search/results';

  /// Đường dẫn mở trang kết quả cho [query]
  static String location(String query, {bool fromSearch = false}) => Uri(
    path: path,
    queryParameters: {'q': query, if (fromSearch) 'from': 'search'},
  ).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchResultsCubit(
        searchRepository: AppEnvironment.useMockData
            ? MockSearchRepository()
            : ApiSearchRepository(),
        query: query,
      )..start(),
      child: TResponsiveLayout(
        mobile: SearchResultsMobileView(fromSearch: fromSearch),
      ),
    );
  }
}
