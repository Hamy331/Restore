import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../../plans/views/plans/plans_view.dart';
import '../../bloc/shop_posters_cubit.dart';
import '../../models/shop_poster.dart';
import '../../utils/poster_labels.dart';
import '../poster_editor/poster_editor_view.dart';
import 'widgets/poster_card.dart';
import 'widgets/poster_filter_bar.dart';
import 'widgets/poster_quota_card.dart';
import 'widgets/poster_stop_sheet.dart';

class ShopPostersMobileView extends StatelessWidget {
  const ShopPostersMobileView({super.key});

  Future<void> _openEditor(BuildContext context, {ShopPoster? poster}) async {
    final cubit = context.read<ShopPostersCubit>();
    final overview = cubit.state.overview;
    if (overview == null) return;
    final l = AppLocalizations.of(context)!;
    final sent = await context.push<bool>(
      PosterEditorView.path,
      extra: PosterEditorArgs(
        limits: overview.limits,
        poster: poster,
        repository: cubit.repository,
      ),
    );
    if (sent != true || !context.mounted) return;
    TSnackBarHelper.showSuccess(context, message: l.spSubmitted);
    await cubit.refresh();
  }

  Future<void> _stop(BuildContext context, ShopPoster poster) async {
    final cubit = context.read<ShopPostersCubit>();
    final l = AppLocalizations.of(context)!;
    final confirmed = await confirmStopPoster(
      context,
      pending: poster.state == ShopPosterState.pending,
    );
    if (!confirmed) return;
    final error = await cubit.stop(poster.id);
    if (!context.mounted) return;
    if (error == null) {
      TSnackBarHelper.showSuccess(context, message: l.spStopped);
    } else {
      TSnackBarHelper.showError(context, message: l.posterError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<ShopPostersCubit, ShopPostersState>(
      builder: (context, state) {
        final cubit = context.read<ShopPostersCubit>();
        final overview = state.overview;
        final canManage =
            overview != null &&
            overview.shop != null &&
            overview.limits.allowed;
        final limits = overview?.limits;
        final canCreate =
            canManage &&
            limits!.monthlyLeft > 0 &&
            limits.cooldownUntil == null;
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
            title: Text(l.spTitle),
          ),
          bottomNavigationBar: canManage
              ? AppBottomActionBar(
                  key: const ValueKey('poster-create'),
                  primaryLabel: l.spCreate,
                  primaryIcon: AppIcons.add,
                  onPrimary: canCreate ? () => _openEditor(context) : null,
                )
              : null,
          body: _body(context, state, cubit),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    ShopPostersState state,
    ShopPostersCubit cubit,
  ) {
    final l = AppLocalizations.of(context)!;
    final overview = state.overview;
    if (overview == null) {
      if (state.status == ShopPostersStatus.failure) {
        return FeedbackView(
          icon: AppIcons.offline,
          title: l.spLoadError,
          message: l.categoryDetailLoadErrorBody,
          action: FilledButton(onPressed: cubit.load, child: Text(l.retry)),
        );
      }
      return const Center(child: AppLoadingIndicator());
    }
    if (overview.shop == null) {
      return FeedbackView(
        icon: AppIcons.store,
        title: l.spNoShopTitle,
        message: l.spNoShopBody,
      );
    }
    if (!overview.limits.allowed) {
      return FeedbackView(
        icon: AppIcons.posterPromo,
        title: l.spPlanTitle,
        message: l.spPlanBody,
        action: FilledButton(
          onPressed: () => context.push(PlansView.path),
          child: Text(l.spSeePlans),
        ),
      );
    }
    final posters = state.visible;
    return AppPullToRefresh(
      onRefresh: cubit.refresh,
      child: ListView(
        key: const ValueKey('shop-posters-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          PosterQuotaCard(overview: overview),
          if (overview.limits.monthlyLeft == 0)
            _Hint(text: l.spMonthlyFull(overview.limits.monthlyLimit)),
          const SizedBox(height: 16),
          if (overview.posters.isNotEmpty) ...[
            PosterFilterBar(
              selected: state.filter,
              countOf: state.count,
              onSelected: cubit.setFilter,
            ),
            const SizedBox(height: 14),
          ],
          if (overview.posters.isEmpty)
            _Empty(title: l.spEmpty, body: l.spEmptyBody)
          else if (posters.isEmpty)
            _Empty(body: l.spEmptyFilter)
          else
            for (final poster in posters)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PosterCard(
                  key: ValueKey('poster-${poster.id}'),
                  poster: poster,
                  busy: state.busyId == poster.id,
                  onEdit: () => _openEditor(context, poster: poster),
                  onStop: () => _stop(context, poster),
                ),
              ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.warning),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({this.title, required this.body});

  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
    child: Column(
      children: [
        const Icon(AppIcons.posterPromo, size: 36, color: AppColors.primary),
        if (title != null) ...[
          const SizedBox(height: 12),
          Text(
            title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
