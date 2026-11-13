import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/credit_wallet/credit_wallet_cubit.dart';
import '../../bloc/credit_wallet/credit_wallet_state.dart';
import '../../widgets/credit_page_scaffold.dart';
import '../credit_history/credit_history_view.dart';
import '../credit_topup/credit_topup_view.dart';
import 'widgets/credit_balance_card.dart';
import 'widgets/credit_recent_section.dart';
import 'widgets/credit_uses_row.dart';

class CreditWalletMobileView extends StatelessWidget {
  const CreditWalletMobileView({super.key});

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/home');

  /// Mở trang nạp; quay về thì tải lại số dư
  Future<void> _topup(BuildContext context) async {
    final cubit = context.read<CreditWalletCubit>();
    await context.push(CreditTopupView.path);
    await cubit.load();
  }

  void _history(BuildContext context) => context.push(CreditHistoryView.path);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CreditPageScaffold(
      title: l10n.creditTitle,
      onBack: () => _back(context),
      trailing: AppCircleIconButton(
        icon: AppIcons.history,
        tooltip: l10n.creditHistoryTitle,
        onTap: () => _history(context),
      ),
      body: BlocBuilder<CreditWalletCubit, CreditWalletState>(
        builder: (context, state) => switch (state.status) {
          CreditWalletStatus.loading => const Center(
            child: AppLoadingIndicator(),
          ),
          CreditWalletStatus.failure => FeedbackView(
            icon: AppIcons.offline,
            title: l10n.creditLoadError,
            message: l10n.creditErrorGeneric,
            action: TextButton(
              onPressed: context.read<CreditWalletCubit>().load,
              child: Text(l10n.retry),
            ),
          ),
          CreditWalletStatus.ready => AppPullToRefresh(
            onRefresh: context.read<CreditWalletCubit>().load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                CreditBalanceCard(
                  wallet: state.wallet,
                  onTopup: () => _topup(context),
                ),
                const SizedBox(height: 20),
                const CreditUsesRow(),
                const SizedBox(height: 20),
                CreditRecentSection(
                  items: state.recent,
                  onSeeAll: () => _history(context),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}
