import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/credit_history/credit_history_cubit.dart';
import '../../bloc/credit_history/credit_history_state.dart';
import '../../widgets/credit_page_scaffold.dart';
import '../../widgets/credit_transaction_tile.dart';
import 'widgets/credit_history_filter_bar.dart';

class CreditHistoryMobileView extends StatelessWidget {
  const CreditHistoryMobileView({super.key});

  /// Gần cuối danh sách thì tải thêm
  bool _onScroll(BuildContext context, ScrollNotification notification) {
    if (notification.metrics.extentAfter < 300) {
      context.read<CreditHistoryCubit>().loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CreditHistoryCubit>();
    return CreditPageScaffold(
      title: l10n.creditHistoryTitle,
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      body: BlocBuilder<CreditHistoryCubit, CreditHistoryState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: CreditHistoryFilterBar(
                selected: state.filter,
                onChanged: cubit.filterChanged,
              ),
            ),
            Expanded(
              child: switch (state.status) {
                CreditHistoryStatus.loading => const Center(
                  child: AppLoadingIndicator(),
                ),
                CreditHistoryStatus.failure => FeedbackView(
                  icon: AppIcons.offline,
                  title: l10n.creditLoadError,
                  message: l10n.creditErrorGeneric,
                  action: TextButton(
                    onPressed: cubit.load,
                    child: Text(l10n.retry),
                  ),
                ),
                CreditHistoryStatus.ready when state.items.isEmpty =>
                  FeedbackView(
                    icon: AppIcons.history,
                    title: l10n.creditEmptyHistory,
                    message: '',
                  ),
                CreditHistoryStatus.ready => RefreshIndicator(
                  onRefresh: cubit.load,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) => _onScroll(context, n),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      children: [
                        AppGlassContainer(
                          showShadow: false,
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              for (var i = 0; i < state.items.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                CreditTransactionTile(item: state.items[i]),
                              ],
                            ],
                          ),
                        ),
                        if (state.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: AppLoadingIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
