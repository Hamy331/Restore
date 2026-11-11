import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';

import '../../../credits/utils/credit_format.dart';
import '../../../credits/views/credit_topup/credit_topup_view.dart';
import '../../bloc/boost_listing_cubit.dart';
import '../../models/listing_promotion.dart';
import 'widgets/boost_card.dart';
import 'widgets/feature_card.dart';
import 'widgets/promotion_confirm_sheet.dart';
import 'widgets/promotion_header.dart';
import 'widgets/promotion_history.dart';

class BoostListingMobileView extends StatelessWidget {
  const BoostListingMobileView({super.key});

  void _close(BuildContext context) {
    final changed = context.read<BoostListingCubit>().state.changed;
    context.canPop() ? context.pop(changed) : context.go('/home');
  }

  Future<void> _topUp(BuildContext context, {int? need}) async {
    final cubit = context.read<BoostListingCubit>();
    await context.push(CreditTopupView.location(need: need));
    await cubit.refresh();
  }

  Future<void> _boost(BuildContext context, ListingPromotion promotion) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<BoostListingCubit>();
    final cost = promotion.boostCost;
    if (cost > promotion.available) {
      return _topUp(context, need: cost - promotion.available);
    }
    final note = promotion.boostFree
        ? l.boostFreeNote(promotion.boostFreeLeft, promotion.boostFreePerMonth)
        : l.boostPayNote(cost);
    final ok = await showPromotionConfirmSheet(
      context,
      title: l.accBoost,
      subtitle: promotion.title,
      icon: AppIcons.boost,
      message: '${l.boostSheetMessage} $note',
      balanceAfter: promotion.boostFree ? null : promotion.available - cost,
      confirmLabel: promotion.boostFree ? l.boostUseFree : l.boostPay(cost),
    );
    if (!ok || !context.mounted) return;
    final outcome = await cubit.boost();
    if (context.mounted) _report(context, outcome);
  }

  Future<void> _feature(
    BuildContext context,
    ListingPromotion promotion,
  ) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<BoostListingCubit>();
    final option = cubit.selectedOption;
    if (option == null) return;
    if (option.credits > promotion.available) {
      return _topUp(context, need: option.credits - promotion.available);
    }
    final ok = await showPromotionConfirmSheet(
      context,
      title: l.featureAction,
      subtitle: promotion.title,
      icon: AppIcons.hot,
      message:
          '${l.promoHistoryFeature(option.durationDays)} · '
          '${CreditFormat.points(context, option.credits)}',
      balanceAfter: promotion.available - option.credits,
      confirmLabel: l.featurePay(option.credits),
    );
    if (!ok || !context.mounted) return;
    final outcome = await cubit.feature();
    if (context.mounted) _report(context, outcome);
  }

  void _report(BuildContext context, PromotionOutcome? outcome) {
    if (outcome == null || !context.mounted) return;
    final l = AppLocalizations.of(context)!;
    final String message;
    switch (outcome) {
      case PromotionDone(:final kind):
        message = kind == PromotionKind.bump ? l.boostDone : l.featureDone;
      case PromotionNeedsTopUp(:final missing):
        _topUp(context, need: missing);
        return;
      case PromotionStillRunning(:final kind, :final until):
        final date = until == null
            ? null
            : CreditFormat.dateTime(context, until);
        message = kind == PromotionKind.bump
            ? (date == null ? l.boostTooSoon(24) : l.promoBoostAgainAt(date))
            : (date == null ? l.accUpdateListingError : l.featureRunning(date));
      case PromotionFailed(message: final text):
        message = text ?? l.accUpdateListingError;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(AppIcons.back, color: AppColors.textPrimary),
            onPressed: () => _close(context),
          ),
          centerTitle: true,
          title: Text(l.promoTitle),
        ),
        body: BlocBuilder<BoostListingCubit, BoostListingState>(
          builder: (context, state) {
            final cubit = context.read<BoostListingCubit>();
            final promotion = state.promotion;
            if (state.status == BoostListingStatus.loading &&
                promotion == null) {
              return const Center(child: AppLoadingIndicator());
            }
            if (promotion == null) {
              return FeedbackView(
                icon: AppIcons.offline,
                title: l.promoLoadError,
                message: l.categoryDetailLoadErrorBody,
                action: FilledButton(
                  onPressed: cubit.load,
                  child: Text(l.retry),
                ),
              );
            }
            final now = DateTime.now();
            return AppPullToRefresh(
              onRefresh: cubit.refresh,
              child: ListView(
                key: const ValueKey('boost-listing-page'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  PromotionHeader(
                    promotion: promotion,
                    now: now,
                    onTopUp: () => _topUp(context),
                  ),
                  const SizedBox(height: 14),
                  if (!promotion.promotable)
                    _Notice(text: l.promoNotPromotable)
                  else ...[
                    BoostCard(
                      promotion: promotion,
                      now: now,
                      busy: state.busy,
                      onBoost: () => _boost(context, promotion),
                    ),
                    const SizedBox(height: 14),
                    FeatureCard(
                      promotion: promotion,
                      now: now,
                      busy: state.busy,
                      selectedPackageId: state.selectedPackageId,
                      onSelect: cubit.selectPackage,
                      onBuy: () => _feature(context, promotion),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PromotionHistory(history: promotion.history, now: now),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('boost-not-promotable'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warningBg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(AppIcons.info, size: 20, color: AppColors.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.warning,
            ),
          ),
        ),
      ],
    ),
  );
}
