import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/search/app_search_header.dart';
import 'package:restore/shared/widgets/search/app_search_input.dart';

import '../../bloc/search_cubit.dart';
import '../../bloc/search_state.dart';
import '../search_results/search_results_view.dart';
import 'widgets/search_idle_content.dart';
import 'widgets/search_suggestion_list.dart';

class SearchMobileView extends StatefulWidget {
  final String initialQuery;

  const SearchMobileView({super.key, this.initialQuery = ''});

  @override
  State<SearchMobileView> createState() => _SearchMobileViewState();
}

class _SearchMobileViewState extends State<SearchMobileView> {
  static const double _contentRadius = 24;
  static const String _nearbyPath = '/nearby';

  late final _controller = TextEditingController(text: widget.initialQuery);
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/home');

  /// Mở trang kết quả; quay lại thì giữ từ khoá trên ô để sửa tiếp
  Future<void> _submit(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return;
    final cubit = context.read<SearchCubit>();
    _setText(query);
    cubit.queryChanged(query);
    _focusNode.unfocus();
    await context.push(SearchResultsView.location(query, fromSearch: true));
    // Từ khoá vừa tìm đã được lưu vào lịch sử
    if (mounted) cubit.loadHistory();
  }

  /// Đưa gợi ý lên ô tìm kiếm để gõ tiếp
  void _fill(String keyword) {
    _setText(keyword);
    context.read<SearchCubit>().queryChanged(keyword);
    _focusNode.requestFocus();
  }

  void _setText(String text) => _controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SearchCubit>();

    return Scaffold(
      backgroundColor: AppHeaderPalette.bottom,
      body: Column(
        children: [
          AppSearchHeader(
            onBack: _back,
            child: AppSearchInput(
              controller: _controller,
              focusNode: _focusNode,
              hintText: l10n.homeSearchHint,
              autofocus: widget.initialQuery.isEmpty,
              onChanged: cubit.queryChanged,
              onSubmitted: _submit,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_contentRadius),
              ),
              child: ColoredBox(
                color: AppColors.surface,
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: state.isTyping
                        ? SearchSuggestionList(
                            key: const ValueKey('suggestions'),
                            state: state,
                            onSubmit: _submit,
                            onFill: _fill,
                            onRemoveHistory: cubit.removeHistory,
                          )
                        : SearchIdleContent(
                            key: const ValueKey('idle'),
                            state: state,
                            onSubmit: _submit,
                            onNearMe: () => context.push(_nearbyPath),
                            onRemoveHistory: cubit.removeHistory,
                            onClearHistory: cubit.clearHistory,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
