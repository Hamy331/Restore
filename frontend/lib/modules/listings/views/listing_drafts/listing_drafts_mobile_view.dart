import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/animations/fade_slide_in.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import '../../models/draft_quota.dart';
import '../../widgets/draft_sheets.dart';
import 'widgets/draft_card.dart';

/// Trang Tin nháp: tin đã lưu nháp, vừa sửa trước. Bấm một tin để soạn tiếp
/// (mở thẳng bước Thông tin cơ bản, hoặc bước chọn danh mục nếu chưa chọn).
class ListingDraftsMobileView extends StatefulWidget {
  const ListingDraftsMobileView({super.key});

  @override
  State<ListingDraftsMobileView> createState() =>
      _ListingDraftsMobileViewState();
}

class _ListingDraftsMobileViewState extends State<ListingDraftsMobileView> {
  @override
  void initState() {
    super.initState();
    context.read<CreateListingBloc>().add(const DraftsRequested());
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _open(ListingModel draft) async {
    final bloc = context.read<CreateListingBloc>();
    // Đang soạn dở tin khác mà chưa lưu: hỏi lưu trước khi mở tin nháp này
    if (bloc.state.hasUnsavedChanges && bloc.state.draft.id != draft.id) {
      final action = await showLeaveDraftSheet(context);
      if (action == null || !mounted) return;
      if (action == LeaveDraftAction.save) {
        final hits = bloc.state.draftLimitHits;
        if (!await bloc.saveDraftAndWait()) {
          if (!mounted) return;
          if (bloc.state.draftLimitHits != hits) {
            // Đang ở trang Tin nháp nên chỉ báo, người dùng xóa bớt ngay tại đây
            await showDraftLimitSheet(
              context,
              limit: bloc.state.draftQuota?.limit,
            );
          } else {
            final l10n = AppLocalizations.of(context)!;
            TSnackBarHelper.showError(context, message: l10n.draftSaveFailed);
          }
          return;
        }
      }
    }
    bloc.add(DraftOpened(draft.id));
  }

  Future<void> _delete(ListingModel draft) async {
    final title = draft.title.trim();
    final confirmed = await showDeleteDraftSheet(
      context,
      title: title.isEmpty ? null : title,
    );
    if (!confirmed || !mounted) return;
    context.read<CreateListingBloc>().add(DraftDeleted(draft.id));
  }

  /// Mở xong: thay trang này bằng bước cần soạn tiếp. Mở từ bước chọn danh
  /// mục (trang này nằm trên bước 1) thì quay lại vẫn về bước 1.
  void _onOpened(CreateListingState state) {
    final next = state.draft.categoryId.isEmpty
        ? CreateListingStep.category
        : CreateListingStep.basicInfo;
    final route = ModalRoute.of(context);
    if (next == CreateListingStep.category && !(route?.isFirst ?? true)) {
      context.pop();
    } else {
      context.pushReplacement(next.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.openDraftStatus != current.openDraftStatus,
          listener: (context, state) {
            if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
            if (state.openDraftStatus == RequestStatus.success) {
              _onOpened(state);
            } else if (state.openDraftStatus == RequestStatus.failure) {
              TSnackBarHelper.showError(context, message: l10n.draftOpenFailed);
            }
          },
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.draftDeleteSuccesses != current.draftDeleteSuccesses,
          listener: (context, state) {
            final title = state.lastDeletedDraftTitle;
            TSnackBarHelper.showSuccess(
              context,
              message: title.isEmpty
                  ? l10n.draftDeleted
                  : l10n.draftDeletedNamed(title),
            );
          },
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.draftDeleteFailures != current.draftDeleteFailures,
          listener: (context, state) => TSnackBarHelper.showError(
            context,
            message: l10n.draftDeleteFailed,
          ),
        ),
      ],
      child: AppGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child:
                      BlocSelector<
                        CreateListingBloc,
                        CreateListingState,
                        DraftQuota?
                      >(
                        selector: (state) => state.draftQuota,
                        builder: (context, quota) => AppPageTitleRow(
                          title: l10n.draftsTitle,
                          subtitle: quota == null
                              ? null
                              : l10n.draftsQuota(quota.used, quota.limit),
                          onBack: _onBack,
                        ),
                      ),
                ),
                Expanded(
                  child: BlocBuilder<CreateListingBloc, CreateListingState>(
                    buildWhen: (previous, current) =>
                        previous.drafts != current.drafts ||
                        previous.draftsStatus != current.draftsStatus ||
                        previous.hasMoreDrafts != current.hasMoreDrafts ||
                        previous.categories != current.categories ||
                        previous.openDraftStatus != current.openDraftStatus ||
                        previous.openingDraftId != current.openingDraftId,
                    builder: (context, state) => _buildBody(context, state),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CreateListingState state) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<CreateListingBloc>();
    final drafts = state.drafts;
    final loading = state.draftsStatus == RequestStatus.loading;

    if (drafts.isEmpty) {
      if (loading || state.draftsStatus == RequestStatus.idle) {
        return const Center(child: AppLoadingIndicator());
      }
      final failed = state.draftsStatus == RequestStatus.failure;
      return Center(
        child: FeedbackView(
          icon: failed ? AppIcons.offline : AppIcons.saveDraft,
          title: failed ? l10n.draftsLoadFailedTitle : l10n.draftsEmptyTitle,
          message: failed
              ? l10n.draftsLoadFailedMessage
              : l10n.draftsEmptyMessage,
          action: failed
              ? FilledButton(
                  onPressed: () => bloc.add(const DraftsRequested()),
                  child: Text(l10n.retry),
                )
              : null,
        ),
      );
    }

    final opening = state.openDraftStatus == RequestStatus.loading;
    return AppPullToRefresh(
      onRefresh: () async {
        bloc.add(const DraftsRequested());
        await bloc.stream.firstWhere(
          (state) => state.draftsStatus != RequestStatus.loading,
        );
      },
      child: AppLoadMoreListener(
        onLoadMore: () => bloc.add(const DraftsRequested(loadMore: true)),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: drafts.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == drafts.length) {
              return AppLoadMoreFooter(
                isLoading: loading && state.hasMoreDrafts,
                hasMore: state.hasMoreDrafts,
              );
            }
            final draft = drafts[index];
            final isOpening = opening && state.openingDraftId == draft.id;
            return FadeSlideIn(
              index: index,
              child: DraftCard(
                draft: draft,
                categoryName: _categoryName(context, state, draft.categoryId),
                isOpening: isOpening,
                onTap: opening ? null : () => _open(draft),
                onDelete: opening ? null : () => _delete(draft),
              ),
            );
          },
        ),
      ),
    );
  }

  String? _categoryName(
    BuildContext context,
    CreateListingState state,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.isEmpty) return null;
    for (final category in state.categories) {
      if (category.id == categoryId) return category.name.of(context);
    }
    return null;
  }
}
