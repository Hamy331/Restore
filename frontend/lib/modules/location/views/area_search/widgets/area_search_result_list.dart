import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../../bloc/area_search/area_search_state.dart';
import '../../../models/area_option.dart';
import 'area_search_tile.dart';

/// Kết quả tìm khu vực theo nội dung đang gõ
class AreaSearchResultList extends StatelessWidget {
  final AreaSearchState state;
  final ValueChanged<AreaOption> onPick;
  final VoidCallback onRetry;

  const AreaSearchResultList({
    super.key,
    required this.state,
    required this.onPick,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    // Đang tìm lần đầu: chưa có gì để hiện
    if (state.status == AreaSearchStatus.searching && state.results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppLoadingIndicator(),
        ),
      );
    }
    if (state.status == AreaSearchStatus.failure) {
      return FeedbackView(
        icon: AppIcons.offline,
        title: l10n.areaSearchErrorTitle,
        message: l10n.searchLoadErrorBody,
        action: FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
      );
    }
    if (state.status == AreaSearchStatus.ready && state.results.isEmpty) {
      return FeedbackView(
        icon: AppIcons.locationUnknown,
        title: l10n.areaNoResultsTitle,
        message: l10n.areaNoResultsBody,
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(top: 10, bottom: bottom + 16),
      children: [
        for (final area in state.results)
          AreaSearchTile(
            area: area,
            highlight: state.query,
            onTap: () => onPick(area),
          ),
      ],
    );
  }
}
