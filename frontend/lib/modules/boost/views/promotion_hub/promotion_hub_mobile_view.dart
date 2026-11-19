import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';

import '../../../account/models/account_listing.dart';
import '../../../credits/utils/credit_format.dart';
import '../../../credits/views/credit_topup/credit_topup_view.dart';
import '../../../listings/models/create_listing_step.dart';
import '../../../listings/models/posting_quota.dart';
import '../../../listings/widgets/display_days_sheet.dart';
import '../../bloc/boost_listing_state.dart';
import '../../bloc/promotion_hub_cubit.dart';
import '../../models/promotion_hub.dart';
import '../boost_listing/boost_listing_view.dart';
import '../boost_listing/widgets/promotion_confirm_sheet.dart';
import 'widgets/hub_filter_bar.dart';
import 'widgets/hub_listing_tile.dart';
import 'widgets/hub_summary.dart';

class PromotionHubMobileView extends StatelessWidget {
  const PromotionHubMobileView({super.key});

  Future<void> _topUp(BuildContext context, {int? need}) async {
    final cubit = context.read<PromotionHubCubit>();
    await context.push(CreditTopupView.location(need: need));
    await cubit.refresh();
  }

  Future<void> _open(BuildContext context, PromotionHubItem item) async {
    final cubit = context.read<PromotionHubCubit>();
    await context.push<bool>(BoostListingView.location(item.id));
    await cubit.refresh();
  }

  void _toast(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _boost(
    BuildContext context,
    PromotionHub hub,
    PromotionHubItem item,
  ) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PromotionHubCubit>();
    final cost = hub.boostCostOf(item);
    if (cost > hub.available) {
      return _topUp(context, need: cost - hub.available);
    }
    final note = hub.boostFree
        ? l.boostFreeNote(hub.freeLeft, hub.freePerMonth)
        : l.boostPayNote(cost);
    final ok = await showPromotionConfirmSheet(
      context,
      title: l.accBoost,
      subtitle: item.title,
      icon: AppIcons.boost,
      message: '${l.boostSheetMessage} $note',
      balanceAfter: hub.boostFree ? null : hub.available - cost,
      confirmLabel: hub.boostFree ? l.boostUseFree : l.boostPay(cost),
    );
    if (!ok || !context.mounted) return;
    final outcome = await cubit.boost(item);
    if (outcome == null || !context.mounted) return;
    switch (outcome) {
      case PromotionDone():
        _toast(context, l.boostDone);
      case PromotionNeedsTopUp(:final missing):
        await _topUp(context, need: missing);
      case PromotionStillRunning(:final until):
        _toast(
          context,
          until == null
              ? l.boostTooSoon(24)
              : l.promoBoostAgainAt(CreditFormat.dateTime(context, until)),
        );
      case PromotionFailed(message: final text):
        _toast(context, text ?? l.accUpdateListingError);
    }
  }

  /// Gia hạn bằng sheet chọn số ngày như ở Quản lý tin
  Future<void> _extend(BuildContext context, PromotionHubItem item) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PromotionHubCubit>();
    final categoryId = item.categoryId;
    if (categoryId == null) return;
    final PostingQuota quota;
    try {
      quota = await cubit.repository.postingQuota();
    } catch (_) {
      if (context.mounted) _toast(context, l.accUpdateListingError);
      return;
    }
    if (!context.mounted) return;
    final rule = quota.forCategory(categoryId);
    final pricing = quota.display;
    final available = quota.walletAvailable;
    final choice = await showDisplayDaysSheet(
      context,
      mode: DisplayDaysMode.extend,
      rule: rule,
      pricing: pricing,
      walletAvailable: available,
      currentEnd: item.expiresAt,
      subtitle: item.title,
    );
    if (choice == null || choice.days <= 0 || !context.mounted) return;
    final price = pricing.extraDaysCredits(choice.days, rule.dayPackCredits);
    if (price > available) {
      return _topUp(context, need: price - available);
    }
    try {
      await cubit.extend(item, choice.days);
      if (context.mounted) _toast(context, l.accExtendedDays(choice.days));
    } on AccountListingActionException catch (error) {
      if (!context.mounted) return;
      switch (error.code) {
        case AccountListingActionException.notEnoughCredits:
          final missing = (error.details['missing'] as num?)?.toInt() ?? price;
          await _topUp(context, need: missing);
        case AccountListingActionException.extendTooLong:
          final addable = (error.details['addableDays'] as num?)?.toInt() ?? 0;
          _toast(
            context,
            addable > 0
                ? l.extendAddable(addable)
                : l.extendLimitReached(rule.maxDisplayDays),
          );
        default:
          _toast(context, error.message ?? l.accUpdateListingError);
      }
    } catch (_) {
      if (context.mounted) _toast(context, l.accUpdateListingError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(AppIcons.back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        centerTitle: true,
        title: Text(l.hubTitle),
      ),
      body: BlocBuilder<PromotionHubCubit, PromotionHubState>(
        builder: (context, state) {
          final cubit = context.read<PromotionHubCubit>();
          final hub = state.hub;
          if (hub == null) {
            if (state.status == PromotionHubStatus.failure) {
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
            return const Center(child: AppLoadingIndicator());
          }
          final now = DateTime.now();
          final counts = {
            for (final filter in PromotionHubFilter.values)
              filter: state.itemsAt(now, filter).length,
          };
          final items = state.itemsAt(now);
          final expiring = counts[PromotionHubFilter.expiring] ?? 0;
          return AppPullToRefresh(
            onRefresh: cubit.refresh,
            child: ListView(
              key: const ValueKey('promotion-hub-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                HubSummary(hub: hub, onTopUp: () => _topUp(context)),
                if (expiring > 0 &&
                    state.filter != PromotionHubFilter.expiring) ...[
                  const SizedBox(height: 10),
                  _ExpiringBanner(
                    text: l.hubExpiringTip(expiring),
                    onTap: () => cubit.setFilter(PromotionHubFilter.expiring),
                  ),
                ],
                const SizedBox(height: 14),
                HubFilterBar(
                  selected: state.filter,
                  counts: counts,
                  onSelected: cubit.setFilter,
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _Empty(filter: state.filter, hasAny: hub.items.isNotEmpty)
                else
                  for (final item in items) ...[
                    HubListingTile(
                      item: item,
                      now: now,
                      boostCost: hub.boostCostOf(item),
                      busy: state.busyId == item.id,
                      onOpen: () => _open(context, item),
                      onBoost: () => _boost(context, hub, item),
                      onExtend: () => _extend(context, item),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExpiringBanner extends StatelessWidget {
  const _ExpiringBanner({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.warningBg,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      key: const ValueKey('hub-expiring-banner'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(AppIcons.warning, size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
            const Icon(
              AppIcons.chevronRight,
              size: 16,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filter, required this.hasAny});
  final PromotionHubFilter filter;
  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = !hasAny
        ? l.promoPickEmpty
        : switch (filter) {
            PromotionHubFilter.all => l.promoPickEmpty,
            PromotionHubFilter.running => l.hubEmptyRunning,
            PromotionHubFilter.expiring => l.hubEmptyExpiring,
            PromotionHubFilter.idle => l.hubEmptyIdle,
          };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            text,
            key: const ValueKey('hub-empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (!hasAny) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(CreateListingStep.category.path),
              child: Text(l.quickActionPost),
            ),
          ],
        ],
      ),
    );
  }
}
