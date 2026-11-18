import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/credit_bonus/credit_bonus_cubit.dart';
import '../../bloc/credit_bonus/credit_bonus_state.dart';
import '../../utils/credit_format.dart';
import '../../widgets/credit_page_scaffold.dart';
import '../credit_wallet/credit_wallet_view.dart';
import 'widgets/credit_bonus_tile.dart';

class CreditBonusMobileView extends StatelessWidget {
  const CreditBonusMobileView({super.key});

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(CreditWalletView.path);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CreditBonusCubit>();
    return CreditPageScaffold(
      title: l10n.creditBonusSheetTitle,
      onBack: () => _back(context),
      body: BlocBuilder<CreditBonusCubit, CreditBonusState>(
        builder: (context, state) => switch (state.status) {
          CreditBonusStatus.loading => const Center(
            child: AppLoadingIndicator(),
          ),
          CreditBonusStatus.failure => FeedbackView(
            icon: AppIcons.offline,
            title: l10n.creditBonusLoadError,
            message: l10n.creditErrorGeneric,
            action: TextButton(onPressed: cubit.load, child: Text(l10n.retry)),
          ),
          CreditBonusStatus.ready => AppPullToRefresh(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _Summary(total: state.total),
                const SizedBox(height: 16),
                if (state.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      l10n.creditBonusEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  for (final item in state.items) CreditBonusTile(item: item),
              ],
            ),
          ),
        },
      ),
    );
  }
}

/// Tổng xu tặng còn lại và cách xu tặng được dùng / hết hạn
class _Summary extends StatelessWidget {
  final int total;

  const _Summary({required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.creditBonusLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CreditFormat.points(context, total),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.creditBonusSheetHint,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
