import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/search/app_search_input.dart';

import '../../bloc/wanted_alert_create/wanted_alert_create_cubit.dart';
import '../../bloc/wanted_alert_create/wanted_alert_create_state.dart';
import '../../models/wanted_alert_match.dart';
import '../../widgets/wanted_alert_page_header.dart';
import '../wanted_alerts/wanted_alerts_view.dart';
import '../../widgets/wanted_alert_glass_scaffold.dart';
import 'widgets/wanted_alert_compose_form.dart';
import 'widgets/wanted_alert_create_filter_bar.dart';
import 'widgets/wanted_alert_suggestions.dart';

class WantedAlertCreateMobileView extends StatefulWidget {
  final String initialKeywords;
  final bool fromAlerts;

  const WantedAlertCreateMobileView({
    super.key,
    this.initialKeywords = '',
    this.fromAlerts = false,
  });

  @override
  State<WantedAlertCreateMobileView> createState() =>
      _WantedAlertCreateMobileViewState();
}

class _WantedAlertCreateMobileViewState
    extends State<WantedAlertCreateMobileView> {
  /// Ô tìm ở bước đầu và ô "Món bạn muốn tìm" ở bước soạn dùng chung nội dung
  late final _keywordsController = TextEditingController(
    text: widget.initialKeywords,
  );
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _keywordsController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _back() {
    final cubit = context.read<WantedAlertCreateCubit>();
    if (cubit.state.step == WantedAlertCreateStep.compose) {
      cubit.backToSearch();
      return;
    }
    context.canPop() ? context.pop() : context.go(WantedAlertsView.path);
  }

  void _compose() {
    FocusScope.of(context).unfocus();
    context.read<WantedAlertCreateCubit>().compose();
  }

  /// Sheet Bộ lọc dùng chung; thông báo không lọc theo khoảng cách
  Future<void> _openFilters() async {
    final cubit = context.read<WantedAlertCreateCubit>();
    final filter = await showListingFilterSheet(
      context,
      filter: cubit.state.draft.filter,
      defaults: WantedAlertCreateState.defaultFilter,
    );
    if (filter != null) cubit.applyFilter(filter);
  }

  /// Trang chọn khu vực, có thêm lựa chọn "Toàn quốc"
  Future<void> _pickArea() async {
    final cubit = context.read<WantedAlertCreateCubit>();
    final result = await context.push<AreaPickResult>(
      AreaSearchView.location(allowNationwide: true),
    );
    if (result == null) return;
    if (result.nationwide) {
      cubit.setArea(null);
    } else if (result.area case final area?) {
      cubit.setArea(area);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WantedAlertCreateCubit>();
    FocusScope.of(context).unfocus();
    final item = await cubit.submit();
    if (!mounted) return;
    if (item == null) {
      TSnackBarHelper.showError(context, message: l10n.wantedAlertCreateError);
      return;
    }
    TSnackBarHelper.showSuccess(
      context,
      message: l10n.wantedAlertCreated(item.alert.keywords),
    );
    if (widget.fromAlerts && context.canPop()) {
      context.pop(item);
    } else {
      context.pushReplacement(WantedAlertsView.path);
    }
  }

  /// Mở tin gợi ý; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openListing(WantedAlertMatch match) async {
    final favorite = await context.push<bool>(
      '/listings/${match.listingId}',
      extra: match.item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<WantedAlertCreateCubit>().syncFavorite(
      match.listingId,
      favorite,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WantedAlertCreateCubit>();

    return BlocBuilder<WantedAlertCreateCubit, WantedAlertCreateState>(
      builder: (context, state) {
        final composing = state.step == WantedAlertCreateStep.compose;
        return PopScope(
          // Đang soạn thì nút quay lại của hệ thống về bước tìm gợi ý
          canPop: !composing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.backToSearch();
          },
          child: WantedAlertGlassScaffold(
            estimatedHeaderHeight: composing ? 64 : 170,
            header: WantedAlertPageHeader(
              title: composing
                  ? l10n.wantedAlertComposeTitle
                  : l10n.wantedAlertTitle,
              subtitle: composing
                  ? l10n.wantedAlertComposeSubtitle
                  : l10n.wantedAlertSubtitle,
              onBack: _back,
              bottom: composing
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AppSearchInput(
                            controller: _keywordsController,
                            focusNode: _searchFocus,
                            hintText: l10n.wantedAlertSearchHint,
                            autofocus: widget.initialKeywords.isEmpty,
                            onChanged: cubit.keywordsChanged,
                            onSubmitted: (_) => _searchFocus.unfocus(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        WantedAlertCreateFilterBar(
                          draft: state.draft,
                          onFiltersTap: _openFilters,
                          onAreaTap: _pickArea,
                          onDealToggle: cubit.toggleDeal,
                          onClearTap: cubit.clearFilters,
                        ),
                      ],
                    ),
            ),
            bodyBuilder: (context, topInset) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: composing
                  ? WantedAlertComposeForm(
                      key: const ValueKey('compose'),
                      state: state,
                      topInset: topInset,
                      keywordsController: _keywordsController,
                      onKeywordsChanged: cubit.keywordsChanged,
                      onEditFilters: _openFilters,
                      onPickArea: _pickArea,
                      onLevelChanged: cubit.setMatchLevel,
                      onOpenListing: _openListing,
                      onFavoriteTap: cubit.toggleFavorite,
                      onRetryPreview: cubit.retryPreview,
                    )
                  : WantedAlertSuggestions(
                      key: const ValueKey('search'),
                      state: state,
                      topInset: topInset,
                      onOpenListing: _openListing,
                      onFavoriteTap: cubit.toggleFavorite,
                      onRetry: cubit.retryPreview,
                    ),
            ),
            bottomNavigationBar: composing
                ? AppBottomActionBar(
                    secondaryLabel: l10n.back,
                    onSecondary: cubit.backToSearch,
                    primaryLabel: l10n.wantedAlertSave,
                    primaryIcon: AppIcons.wantedAlert,
                    onPrimary: state.draft.hasKeywords ? _submit : null,
                    isLoading: state.isSubmitting,
                  )
                : AppBottomActionBar(
                    primaryLabel: state.draft.hasKeywords
                        ? l10n.wantedAlertNotRightCta
                        : l10n.wantedAlertSkipToCompose,
                    primaryIcon: AppIcons.wantedAlert,
                    onPrimary: _compose,
                  ),
          ),
        );
      },
    );
  }
}
