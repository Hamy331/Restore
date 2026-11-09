import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/credit_topup/credit_topup_cubit.dart';
import '../../bloc/credit_topup/credit_topup_state.dart';
import '../../models/topup_step.dart';
import '../../utils/credit_format.dart';
import '../../widgets/credit_page_scaffold.dart';
import 'widgets/topup_confirm_section.dart';
import 'widgets/topup_package_section.dart';
import 'widgets/topup_pay_section.dart';
import 'widgets/topup_result_section.dart';

class CreditTopupMobileView extends StatelessWidget {
  const CreditTopupMobileView({super.key});

  /// Lùi một bước trong luồng; ở bước đầu hoặc kết quả thì đóng trang
  void _back(BuildContext context) {
    if (context.read<CreditTopupCubit>().back()) return;
    context.canPop() ? context.pop() : context.go('/home');
  }

  String _title(AppLocalizations l10n, CreditTopupState state) =>
      switch (state.step) {
        TopupStep.choose => l10n.creditTopupTitle,
        TopupStep.confirm => l10n.creditConfirmTitle,
        TopupStep.pay =>
          state.order?.method == CreditPayMethod.vietQr
              ? l10n.creditPayBankTitle
              : l10n.creditPayVnpayTitle,
        TopupStep.result => l10n.creditResultTitle,
      };

  /// Báo lỗi một lần cho mỗi lần gọi API hỏng
  void _onError(BuildContext context, CreditTopupState state) {
    final l10n = AppLocalizations.of(context)!;
    TSnackBarHelper.showError(
      context,
      message: state.errorCode == 'TOPUP_TOO_MANY_PENDING'
          ? l10n.creditErrorTooManyPending
          : l10n.creditErrorGeneric,
    );
  }

  Widget? _bottom(
    BuildContext context,
    AppLocalizations l10n,
    CreditTopupState state,
  ) {
    final cubit = context.read<CreditTopupCubit>();
    final price = state.selected == null
        ? ''
        : CreditFormat.vnd(context, state.selected!.priceVnd);
    return switch (state.step) {
      TopupStep.choose when state.loadStatus == TopupLoadStatus.ready =>
        AppBottomActionBar(
          primaryLabel: l10n.creditContinue(price),
          onPrimary: state.selected == null ? null : cubit.next,
        ),
      TopupStep.confirm => AppBottomActionBar(
        primaryLabel: l10n.creditPayAction(price),
        onPrimary: state.agreed ? cubit.pay : null,
        isLoading: state.busy,
      ),
      TopupStep.result => AppBottomActionBar(
        primaryLabel: switch (state.outcome) {
          TopupOutcome.success => l10n.creditDone,
          TopupOutcome.pending => l10n.creditCheckAgain,
          TopupOutcome.failed => l10n.creditTryAgain,
        },
        onPrimary: switch (state.outcome) {
          TopupOutcome.success =>
            () => context.canPop() ? context.pop(true) : context.go('/home'),
          TopupOutcome.pending => cubit.refresh,
          TopupOutcome.failed => cubit.retry,
        },
        isLoading: state.busy,
        secondaryLabel: state.outcome == TopupOutcome.success
            ? null
            : l10n.creditBackToWallet,
        onSecondary: () =>
            context.canPop() ? context.pop() : context.go('/home'),
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<CreditTopupCubit, CreditTopupState>(
      listenWhen: (prev, next) =>
          next.errorCode != null && prev.errorCode != next.errorCode,
      listener: _onError,
      builder: (context, state) {
        final cubit = context.read<CreditTopupCubit>();
        final Widget body = switch (state.loadStatus) {
          TopupLoadStatus.loading => const Center(child: AppLoadingIndicator()),
          TopupLoadStatus.failure => FeedbackView(
            icon: AppIcons.offline,
            title: l10n.creditPackagesError,
            message: l10n.creditErrorGeneric,
            action: TextButton(onPressed: cubit.load, child: Text(l10n.retry)),
          ),
          TopupLoadStatus.ready => AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(state.step),
              child: switch (state.step) {
                TopupStep.choose => const TopupPackageSection(),
                TopupStep.confirm => const TopupConfirmSection(),
                TopupStep.pay => const TopupPaySection(),
                TopupStep.result => const TopupResultSection(),
              },
            ),
          ),
        };
        return PopScope(
          canPop:
              state.step == TopupStep.choose || state.step == TopupStep.result,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.back();
          },
          child: CreditPageScaffold(
            title: _title(l10n, state),
            onBack: () => _back(context),
            body: body,
            bottom: _bottom(context, l10n, state),
          ),
        );
      },
    );
  }
}
