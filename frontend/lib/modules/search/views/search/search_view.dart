import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/shared/widgets/desktop/desktop_header.dart';

import '../../bloc/search_cubit.dart';
import '../../repositories/search_repository.dart';
import '../../utils/open_listing_search.dart';
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
        showHistory: context.isSignedIn,
      )..start(),
      child: TResponsiveLayout(
        mobile: SearchMobileView(initialQuery: initialQuery),
        desktop: _DesktopSearchRedirect(initialQuery: initialQuery),
      ),
    );
  }
}

/// Desktop không có trang tìm kiếm riêng (ô tìm kiếm trên header đã có khung
/// gợi ý): có từ khoá thì mở thẳng kết quả / trang danh mục, không thì quay
/// về trang trước và đặt con trỏ vào ô tìm kiếm trên header
class _DesktopSearchRedirect extends StatefulWidget {
  const _DesktopSearchRedirect({required this.initialQuery});

  final String initialQuery;

  @override
  State<_DesktopSearchRedirect> createState() => _DesktopSearchRedirectState();
}

class _DesktopSearchRedirectState extends State<_DesktopSearchRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final query = widget.initialQuery.trim();
    if (query.isNotEmpty) {
      final target = await listingSearchDestination(context, query);
      if (mounted) {
        context.pushReplacement(target.location, extra: target.extra);
      }
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
    DesktopHeader.requestSearch();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
