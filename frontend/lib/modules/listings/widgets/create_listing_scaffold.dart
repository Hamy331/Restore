import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import '../bloc/create_listing/create_listing_bloc.dart';
import '../bloc/create_listing/create_listing_state.dart';
import '../models/create_listing_step.dart';
import '../utils/listing_save_error.dart';
import '../views/listing_drafts/listing_drafts_view.dart';
import 'draft_sheets.dart';

/// Bề rộng tối đa của nội dung các bước đăng tin trên màn hình lớn
const double createListingMaxWidth = 720;

/// Khung chung của 3 bước đăng tin: nút đóng (X), nút Lưu nháp, thanh tiến
/// trình 3 đoạn, nội dung cuộn và thanh nút cuối trang. Trên desktop nội
/// dung nằm giữa trong khung [maxWidth].
class CreateListingScaffold extends StatelessWidget {
  final CreateListingStep step;

  /// Tiêu đề lớn đầu nội dung (null = không có)
  final String? title;
  final List<Widget> children;
  final Widget? bottomBar;
  final bool showSaveDraft;
  final double maxWidth;

  const CreateListingScaffold({
    super.key,
    required this.step,
    required this.children,
    this.title,
    this.bottomBar,
    this.showSaveDraft = true,
    this.maxWidth = createListingMaxWidth,
  });

  void _onSaveDraftChanged(BuildContext context, CreateListingState state) {
    // Nhiều bước cùng nằm trong stack nên chỉ trang đang hiển thị báo kết quả
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    if (state.saveDraftStatus == RequestStatus.success) {
      TSnackBarHelper.showSuccess(context, message: l10n.draftSaved);
    } else if (state.saveDraftStatus == RequestStatus.failure) {
      TSnackBarHelper.showError(
        context,
        message: listingSaveErrorText(
          l10n,
          state.saveError,
          fallback: l10n.draftSaveFailed,
        ),
      );
    }
  }

  void _onDraftLimitHit(BuildContext context, CreateListingState state) {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    showDraftLimitSheet(
      context,
      limit: state.draftQuota?.limit,
      onViewDrafts: () => context.push(ListingDraftsView.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final desktop = isDesktopLayout(context);
    final isEditing = context.select(
      (CreateListingBloc bloc) => bloc.state.isEditing,
    );
    final hasUnsaved = context.select(
      (CreateListingBloc bloc) => bloc.state.hasUnsavedChanges,
    );
    // Đang lưu nháp / đăng tin: khóa mọi thao tác khác để nội dung không đổi
    // giữa chừng
    final busy = context.select(
      (CreateListingBloc bloc) =>
          bloc.state.saveDraftStatus == RequestStatus.loading ||
          bloc.state.publishStatus == RequestStatus.loading,
    );
    final isFlowEntry = ModalRoute.of(context)?.isFirst ?? true;
    final horizontal = desktop ? 24.0 : 16.0;

    Widget centered(Widget child) => Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.saveDraftStatus != current.saveDraftStatus,
          listener: _onSaveDraftChanged,
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.draftLimitHits != current.draftLimitHits,
          listener: _onDraftLimitHit,
        ),
      ],
      child: PopScope(
        // Nút quay lại của hệ thống: trang đầu luồng còn nội dung chưa lưu
        // thì hỏi lưu nháp trước khi thoát
        canPop: !busy && !(isFlowEntry && hasUnsaved),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !busy) closeCreateListingFlow(context);
        },
        child: Scaffold(
          backgroundColor: desktop ? AppColors.fill : AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Desktop: đầu trang nằm trên nền xám, chỉ thẻ nội dung trắng
                ColoredBox(
                  color: desktop ? AppColors.fill : AppColors.background,
                  child: centered(
                    _Header(
                      step: step,
                      busy: busy,
                      horizontal: horizontal,
                      saveDraftLabel: showSaveDraft && !isEditing
                          ? l10n.saveDraft
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: _Locked(
                    locked: busy,
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        0,
                        desktop ? 24 : 4,
                        0,
                        desktop ? 40 : 28,
                      ),
                      children: [
                        centered(
                          _Body(
                            desktop: desktop,
                            horizontal: horizontal,
                            title: title,
                            children: children,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: bottomBar == null
              ? null
              : _Locked(
                  locked: busy,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: desktop ? AppColors.fill : AppColors.background,
                      boxShadow: [
                        if (!desktop)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                      ],
                      border: desktop
                          ? const Border(
                              top: BorderSide(color: AppColors.border),
                            )
                          : null,
                    ),
                    child: SafeArea(top: false, child: centered(bottomBar!)),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Đóng cả luồng đăng tin. Còn nội dung chưa lưu thì hỏi lưu nháp (đang sửa
/// tin đã đăng thì hỏi bỏ thay đổi) trước khi thoát.
Future<void> closeCreateListingFlow(BuildContext context) async {
  final bloc = context.read<CreateListingBloc>();
  final state = bloc.state;
  if (state.saveDraftStatus == RequestStatus.loading ||
      state.publishStatus == RequestStatus.loading) {
    return;
  }
  if (state.hasUnsavedChanges) {
    if (state.isEditing) {
      if (!await showLeaveEditSheet(context)) return;
    } else {
      final action = await showLeaveDraftSheet(context);
      if (action == null || !context.mounted) return;
      // Lỗi hoặc đủ số tin nháp thì ở lại, listener của trang đã báo
      if (action == LeaveDraftAction.save && !await bloc.saveDraftAndWait()) {
        return;
      }
    }
  }
  if (!context.mounted) return;
  exitCreateListingFlow(context);
}

/// Thoát hẳn luồng đăng tin (bloc bị huỷ theo): các bước nằm trong navigator
/// riêng của luồng nên gỡ cả trang chứa luồng ở navigator cha. Mở thẳng
/// bằng đường dẫn (không có trang phía dưới) thì về trang chủ.
void exitCreateListingFlow(BuildContext context, [Object? result]) {
  final flow = Navigator.of(context);
  // Navigator.maybeOf(flow.context) trả về chính flow nên tìm ngược lên cha
  final parent = flow.context.findAncestorStateOfType<NavigatorState>();
  if (parent != null && parent.canPop()) {
    parent.pop(result);
  } else {
    GoRouter.of(context).go('/home');
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.busy,
    required this.horizontal,
    required this.saveDraftLabel,
  });

  final CreateListingStep step;
  final bool busy;
  final double horizontal;

  /// null = không hiện nút Lưu nháp
  final String? saveDraftLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal - 8, 4, horizontal - 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    AppIcons.close,
                    size: 26,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: busy
                      ? null
                      : () => closeCreateListingFlow(context),
                ),
                const Spacer(),
                if (saveDraftLabel != null)
                  _SaveDraftButton(label: saveDraftLabel!),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 4, 0),
            child: CreateListingProgress(step: step),
          ),
        ],
      ),
    );
  }
}

/// Thanh tiến trình 3 đoạn, đoạn đã qua và đang ở tô màu chính
class CreateListingProgress extends StatelessWidget {
  const CreateListingProgress({super.key, required this.step});

  final CreateListingStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.stepProgressLabel(step.number, CreateListingStep.total),
      child: Row(
        children: [
          for (var i = 0; i < CreateListingStep.total; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  color: i < step.number
                      ? AppColors.actionPrimary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.desktop,
    required this.horizontal,
    required this.title,
    required this.children,
  });

  final bool desktop;
  final double horizontal;
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        desktop ? 28 : 20,
        horizontal,
        desktop ? 32 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
          ],
          ...children,
        ],
      ),
    );
    if (!desktop) return content;
    // Desktop: nội dung trên một tấm nền trắng giữa trang xám nhạt
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }
}

/// Thanh cuối trang: "Quay lại" bên trái, nút chính bên phải
class CreateListingBottomBar extends StatelessWidget {
  const CreateListingBottomBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.isLoading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// null = không có nút Quay lại
  final VoidCallback? onBack;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: onBack == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerLeft,
                    heightFactor: 1,
                    child: TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.actionPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        l10n.back,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: isLoading ? null : onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.actionPrimary,
                  foregroundColor: AppColors.onAction,
                  disabledBackgroundColor: AppColors.actionPrimary.withValues(
                    alpha: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const AppLoadingIndicator(dotSize: 6, color: Colors.white)
                    : Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chặn chạm vào [child] và làm mờ nhẹ khi [locked]
class _Locked extends StatelessWidget {
  final bool locked;
  final Widget child;
  const _Locked({required this.locked, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: locked,
      child: AnimatedOpacity(
        opacity: locked ? 0.6 : 1,
        duration: const Duration(milliseconds: 150),
        child: child,
      ),
    );
  }
}

class _SaveDraftButton extends StatelessWidget {
  final String label;
  const _SaveDraftButton({required this.label});

  /// Lưu xong thì thoát luồng đăng tin về trang chủ (tin nằm trong Tin
  /// nháp). Lỗi hoặc đủ số tin nháp thì ở lại, listener của trang đã báo.
  Future<void> _save(BuildContext context) async {
    final saved = await context.read<CreateListingBloc>().saveDraftAndWait();
    if (saved && context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select(
      (CreateListingBloc bloc) =>
          bloc.state.saveDraftStatus == RequestStatus.loading,
    );
    final hasContent = context.select(
      (CreateListingBloc bloc) => bloc.state.draft.hasContent,
    );
    return TextButton(
      onPressed: isSaving || !hasContent ? null : () => _save(context),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.actionPrimary,
        disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.6),
        minimumSize: const Size(0, 40),
      ),
      child: isSaving
          ? const AppLoadingIndicator(dotSize: 4)
          : Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
    );
  }
}
