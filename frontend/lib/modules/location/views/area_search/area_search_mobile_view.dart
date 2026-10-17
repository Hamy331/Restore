import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/search/app_search_header.dart';
import 'package:restore/shared/widgets/search/app_search_input.dart';

import '../../bloc/area_search/area_search_cubit.dart';
import '../../bloc/area_search/area_search_state.dart';
import '../../models/area_option.dart';
import 'widgets/area_search_idle_content.dart';
import 'widgets/area_search_result_list.dart';

class AreaSearchMobileView extends StatefulWidget {
  const AreaSearchMobileView({super.key});

  @override
  State<AreaSearchMobileView> createState() => _AreaSearchMobileViewState();
}

class _AreaSearchMobileViewState extends State<AreaSearchMobileView> {
  static const double _contentRadius = 24;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _back() => context.pop();

  void _pickMyLocation() => context.pop(const AreaPickResult.myLocation());

  void _pickArea(AreaOption area) {
    context.read<AreaSearchCubit>().remember(area);
    context.pop(AreaPickResult.area(area));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AreaSearchCubit>();

    return Scaffold(
      backgroundColor: AppHeaderPalette.bottom,
      body: Column(
        children: [
          AppSearchHeader(
            onBack: _back,
            child: AppSearchInput(
              controller: _controller,
              icon: AppIcons.location,
              hintText: l10n.areaSearchHint,
              autofocus: true,
              onChanged: cubit.queryChanged,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_contentRadius),
              ),
              child: ColoredBox(
                color: AppColors.surface,
                child: BlocBuilder<AreaSearchCubit, AreaSearchState>(
                  builder: (context, state) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: state.isTyping
                        ? AreaSearchResultList(
                            key: const ValueKey('results'),
                            state: state,
                            onPick: _pickArea,
                            onRetry: cubit.retry,
                          )
                        : AreaSearchIdleContent(
                            key: const ValueKey('idle'),
                            recent: state.recent,
                            onMyLocation: _pickMyLocation,
                            onPick: _pickArea,
                            onRemove: cubit.removeRecent,
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
