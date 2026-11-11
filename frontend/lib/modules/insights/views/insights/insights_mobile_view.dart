import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../../boost/views/boost_listing/boost_listing_view.dart';
import '../../../boost/views/promotion_hub/promotion_hub_view.dart';
import '../../bloc/insights_cubit.dart';
import '../../models/seller_insights.dart';
import '../../repositories/insights_repository.dart';
import 'widgets/insight_card.dart';
import 'widgets/insight_kpi_tile.dart';
import 'widgets/insight_listing_counts.dart';
import 'widgets/insight_tips.dart';
import 'widgets/insight_top_listings.dart';
import 'widgets/insight_views_chart.dart';

class InsightsMobileView extends StatelessWidget {
  const InsightsMobileView({super.key});

  /// Ngày backend bắt đầu ghi lượt xem theo ngày: kỳ bắt đầu trước đó thì
  /// nhắc rằng biểu đồ chưa đủ dữ liệu
  static final DateTime _dailyViewsSince = DateTime(2026, 11, 11);

  Future<void> _push(BuildContext context, String location) async {
    final cubit = context.read<InsightsCubit>();
    await context.push(location);
    await cubit.refresh();
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
        title: Text(l.insTitle),
      ),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          final cubit = context.read<InsightsCubit>();
          final insights = state.insights;
          final current = insights != null && insights.days == state.days;
          if (state.status == InsightsStatus.failure && !current) {
            return FeedbackView(
              icon: AppIcons.offline,
              title: l.insLoadError,
              message: l.categoryDetailLoadErrorBody,
              action: FilledButton(onPressed: cubit.load, child: Text(l.retry)),
            );
          }
          return AppPullToRefresh(
            onRefresh: cubit.refresh,
            child: ListView(
              key: const ValueKey('insights-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _RangeSwitch(selected: state.days, onSelected: cubit.setDays),
                const SizedBox(height: 14),
                if (!current)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: AppLoadingIndicator()),
                  )
                else
                  ..._content(context, state, insights),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    InsightsState state,
    SellerInsights insights,
  ) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<InsightsCubit>();
    final now = DateTime.now();
    final best = insights.top.isEmpty ? null : insights.top.first;
    final tips = <Widget>[
      if (insights.expiringSoon > 0)
        InsightTip(
          key: const ValueKey('ins-tip-expiring'),
          icon: AppIcons.warning,
          text: l.insTipExpiring(insights.expiringSoon),
          color: AppColors.warning,
          background: AppColors.warningBg,
          onTap: () => _push(context, PromotionHubView.path),
        ),
      if (best != null && best.views > 0 && !best.isPromotedAt(now))
        InsightTip(
          key: const ValueKey('ins-tip-boost'),
          icon: AppIcons.boost,
          text: l.insTipBoost(best.title),
          onTap: () => _push(context, BoostListingView.location(best.id)),
        ),
      if (insights.active > 0 && insights.views.value == 0)
        InsightTip(
          key: const ValueKey('ins-tip-no-views'),
          icon: AppIcons.info,
          text: l.insTipNoViews,
          color: AppColors.info,
          background: AppColors.infoBg,
        ),
    ];
    return [
      Row(
        children: [
          Expanded(
            child: InsightKpiTile(
              key: const ValueKey('ins-kpi-views'),
              icon: AppIcons.visible,
              label: l.insViews,
              metric: insights.views,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InsightKpiTile(
              key: const ValueKey('ins-kpi-saves'),
              icon: AppIcons.favorite,
              label: l.insSaves,
              metric: insights.saves,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      InsightKpiTile(
        key: const ValueKey('ins-kpi-chats'),
        icon: AppIcons.chat,
        label: l.insChats,
        metric: insights.chats,
      ),
      if (tips.isNotEmpty) ...[
        const SizedBox(height: 14),
        InsightCard(
          title: l.insTipsTitle,
          child: Column(
            children: [
              for (final (index, tip) in tips.indexed) ...[
                if (index > 0) const SizedBox(height: 8),
                tip,
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 14),
      InsightCard(
        title: l.insChartTitle,
        child: insights.daily.every((d) => d.views == 0)
            ? Text(
                l.insChartEmpty,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : InsightViewsChart(
                days: insights.daily,
                selected: state.selectedDay,
                onSelect: cubit.selectDay,
              ),
      ),
      const SizedBox(height: 14),
      InsightCard(
        title: l.insTopTitle,
        child: InsightTopListings(
          items: insights.top,
          now: now,
          onOpen: (item) => _push(context, BoostListingView.location(item.id)),
        ),
      ),
      const SizedBox(height: 14),
      InsightCard(
        title: l.insListingsTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InsightListingCounts(insights: insights),
            const Divider(height: 24),
            InkWell(
              key: const ValueKey('ins-promotions'),
              onTap: () => _push(context, PromotionHubView.path),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.boost,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.insPromotions(insights.boosts, insights.features),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    AppIcons.chevronRight,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (insights.daily.isNotEmpty &&
          insights.daily.first.date.isBefore(_dailyViewsSince)) ...[
        const SizedBox(height: 12),
        Text(
          l.insViewsNote,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ];
  }
}

/// Chọn 7 / 30 ngày
class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SegmentedButton<int>(
      key: const ValueKey('ins-range'),
      showSelectedIcon: false,
      segments: [
        for (final days in InsightsRepository.ranges)
          ButtonSegment(value: days, label: Text(l.insRangeDays(days))),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onSelected(value.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primarySoft,
        selectedForegroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
