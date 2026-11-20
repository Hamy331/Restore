import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
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

  void _search() {
    FocusScope.of(context).unfocus();
    context.read<FeedsCubit>().search(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            maxLength: 200,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: l.feedSearchHint,
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: IconButton(
                tooltip: l.feedSearchHint,
                icon: const Icon(AppIcons.search, color: AppColors.textPrimary),
                onPressed: _search,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: const Icon(AppIcons.close, size: 20),
                      onPressed: () {
                        _controller.clear();
                        _search();
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
