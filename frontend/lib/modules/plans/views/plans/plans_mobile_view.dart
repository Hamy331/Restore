import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/plans_cubit.dart';
import '../../bloc/plans_state.dart';
import '../../models/plan_package.dart';
import 'widgets/plan_card.dart';
import 'widgets/plan_checkout_sheet.dart';

class PlansMobileView extends StatelessWidget {
  const PlansMobileView({super.key});

  static bool _busy = false;

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/home');

  /// Báo giá, hỏi lại trong sheet rồi trả xu (hoặc mở trang nạp)
  Future<void> _choose(BuildContext context, PlanPackage package) async {
    if (_busy) return;
    _busy = true;
    try {
      await _checkout(context, package);
    } finally {
      _busy = false;
    }
  }

  Future<void> _checkout(BuildContext context, PlanPackage package) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PlansCubit>();
    final PlanQuote quote;
    try {
      quote = await cubit.repository.quote(package.id);
    } on PlanActionException catch (error) {
      if (context.mounted) {
        TSnackBarHelper.showInfo(
          context,
          message: error.message ?? l10n.plansActionError,
        );
      }
      return;
    } catch (_) {
      if (context.mounted) {
        TSnackBarHelper.showError(context, message: l10n.plansActionError);
      }
      return;
    }
    if (!context.mounted) return;
    final result = await showAppGlassSheet<PlanCheckoutResult>(
      context,
      title: package.plan.label(l10n),
      subtitle: l10n.plansPrice(package.priceCredits),
      icon: AppIcons.pro,
      builder: (_) => PlanCheckoutSheet(
        quote: quote,
        categories: cubit.state.categories,
        initialCategoryId: cubit.state.current?.categoryId,
      ),
    );
    if (!context.mounted) return;
    switch (result) {
      case PlanCheckoutTopUp():
        await context.push(
          CreditTopupView.location(need: quote.amount - quote.available),
        );
      case PlanCheckoutPay(:final categoryId):
        try {
          await cubit.subscribe(package.id, categoryId: categoryId);
          if (context.mounted) {
            TSnackBarHelper.showSuccess(
              context,
              message: l10n.plansActivated(package.plan.label(l10n)),
            );
          }
        } on PlanActionException catch (error) {
          if (!context.mounted) return;
          if (error.code == PlanActionException.notEnoughCredits) {
            final missing =
                (error.details['missing'] as num?)?.toInt() ?? quote.amount;
            await context.push(CreditTopupView.location(need: missing));
            return;
          }
          TSnackBarHelper.showInfo(
            context,
            message: error.message ?? l10n.plansActionError,
          );
        } catch (_) {
          if (context.mounted) {
            TSnackBarHelper.showError(context, message: l10n.plansActionError);
          }
        }
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGlassBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: AppPageTitleRow(
                  title: l10n.plansTitle,
                  subtitle: l10n.plansSubtitle,
                  onBack: () => _back(context),
                ),
              ),
              Expanded(
                child: BlocBuilder<PlansCubit, PlansState>(
                  builder: (context, state) => switch (state.status) {
                    PlansStatus.loading => const Center(
                      child: AppLoadingIndicator(),
                    ),
                    PlansStatus.failure => FeedbackView(
                      icon: AppIcons.offline,
                      title: l10n.plansLoadError,
                      message: l10n.plansActionError,
                      action: TextButton(
                        onPressed: context.read<PlansCubit>().load,
                        child: Text(l10n.retry),
                      ),
                    ),
                    PlansStatus.ready => RefreshIndicator(
                      onRefresh: () =>
                          context.read<PlansCubit>().load(showLoading: false),
                      child: _PlanList(
                        state: state,
                        onChoose: (package) => _choose(context, package),
                      ),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.state, required this.onChoose});

  final PlansState state;
  final ValueChanged<PlanPackage> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final current = state.current;
    final active = current != null && current.isActiveAt(now) ? current : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (active != null) ...[
          Text(
            '${l10n.plansCurrent}: ${active.package.plan.label(l10n)} · '
            '${l10n.plansCurrentUntil(DateFormat('dd/MM/yyyy').format(active.endsAt!))}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
        ],
        PlanCard(
          plan: SubscriptionPlan.personal,
          price: l10n.plansFree,
          isCurrent: active == null,
          benefits: [
            l10n.plansPersonalBenefitFree,
            l10n.plansPersonalBenefitPay,
          ],
        ),
        for (final package in state.packages) ...[
          const SizedBox(height: 12),
          _paidCard(l10n, package, active),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.plansNote,
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _paidCard(
    AppLocalizations l10n,
    PlanPackage package,
    CurrentPlan? active,
  ) {
    final isCurrent = active?.package.id == package.id;
    final lower =
        active != null &&
        !isCurrent &&
        package.priorityLevel <= active.package.priorityLevel;
    return PlanCard(
      plan: package.plan,
      price: l10n.plansPrice(package.priceCredits),
      isCurrent: isCurrent,
      benefits: [
        l10n.plansBenefitActive(package.activeListingLimit),
        l10n.plansBenefitDaily(package.dailyListingLimit),
        l10n.plansBenefitDrafts(package.draftLimit),
        if (package.monthlyPromotionQuota > 0)
          l10n.plansBenefitBoosts(package.monthlyPromotionQuota),
        if (package.boostDiscountPercent > 0)
          l10n.plansBenefitBoostDiscount(package.boostDiscountPercent),
        if (package.priorityLevel > 0) l10n.plansBenefitPriority,
        if (package.plan == SubscriptionPlan.shop) l10n.plansBenefitShopPage,
      ],
      actionLabel: isCurrent
          ? l10n.plansRenew
          : active == null
          ? l10n.plansBuy
          : l10n.plansUpgrade,
      onAction: lower ? null : () => onChoose(package),
      lockedHint: lower ? l10n.plansLowerLocked : null,
    );
  }
}
