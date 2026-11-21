import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_list_search_bar.dart';

import '../bloc/feeds/feeds_cubit.dart';

class FeedSearchBar extends StatefulWidget {
  const FeedSearchBar({super.key});

  @override
  State<FeedSearchBar> createState() => _FeedSearchBarState();
}

class _FeedSearchBarState extends State<FeedSearchBar> {
  late final _controller = TextEditingController(
    text: context.read<FeedsCubit>().state.searchQuery,
  );

  void _search() => context.read<FeedsCubit>().search(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppListSearchBar(
    controller: _controller,
    hintText: AppLocalizations.of(context)!.feedSearchHint,
    onSearch: _search,
  );
}
